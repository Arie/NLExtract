__author__ = "Milo van der Linden"
__date__ = "$Jun 14, 2011 11:11:01 AM$"

"""
 Naam:         processor.py
 Omschrijving: Processing van parsed BAG DOM en CSV objecten

 Auteur:       Milo van der Linden Just van den Broecke

 Versie:       1.0
               - basis versie
 Datum:        22 december 2011


 OpenGeoGroep.nl
"""

from bagobject import BAGObjectFabriek
from bestuurlijkobject import BestuurlijkObjectFabriek
from postgresdb import Database
from log import Log
from etree import etree,stripschema,stripNS

class Processor:
    def __init__(self):
        self.database = Database()

    def processCSV(self, csvreader):
        objecten = []
        cols = csvreader.next()
        for record in csvreader:
            if record[0]:
                object = BestuurlijkObjectFabriek(cols, record)
                if object:
                    objecten.append(object)
                else:
                    Log.log.warn("Geen object gevonden voor " + str(record))

        # Verwerk het bestand, lees gemeente_woonplaatsen in de database
        Log.log.info("Insert objectCount=" + str(len(objecten)))
        self.database.verbind()

        # We gaan er even vanuit dat de encoding van de CSVs UTF-8 is
        self.database.connection.set_client_encoding('UTF8')
        for object in objecten:
            object.insert()
            self.database.uitvoeren(object.sql, object.valuelist)
        self.database.connection.commit()

    def processDOM(self, node):
        self.bagObjecten = []
        mode = "Onbekend"
        if stripschema(node.tag) == 'BAG-Extract-Deelbestand-LVC':
            mode = 'Nieuw'
            #firstchild moet zijn 'antwoord'
            for childNode in node:
                if stripschema(childNode.tag) == 'antwoord':
                    # Antwoord bevat twee childs: vraag en producten
                    antwoord = childNode
                    for child in antwoord:
                        if stripschema(child.tag) == "vraag":
                            # TODO: Is het een idee om vraag als object ook af te
                            # handelen en op te slaan
                            vraag = child
                        elif stripschema(child.tag) == "producten":
                            producten = child
                            Log.log.startTimer("objCreate")
                            for productnode in producten:
                                if stripschema(productnode.tag) == 'LVC-product':
                                    self.bagObjecten = BAGObjectFabriek.bof.BAGObjectArrayBijXML(productnode)
                            bericht = Log.log.endTimer("objCreate - objs=" + str(len(self.bagObjecten)))
                            Database().log_actie('create_objects', 'idem', bericht)

        elif stripschema(node.tag) == 'BAG-Mutaties-Deelbestand-LVC':
            mode = 'Mutatie'
            #firstchild moet zijn 'antwoord'
            for childNode in node:
                if stripschema(childNode.tag) == 'antwoord':
                    # Antwoord bevat twee childs: vraag en producten
                    antwoord = childNode
                    for child in antwoord:
                        if stripschema(child.tag) == "producten":
                            producten = child
                            Log.log.startTimer("objCreate (mutaties)")
                            for productnode in producten:
                                if stripschema(productnode.tag) == 'Mutatie-product':
                                    origineelObj = None
                                    nieuwObj = None
                                    for mutatienode in productnode:
                                        if stripschema(mutatienode.tag) == 'Nieuw':
                                            # Log.log.info("Nieuw Object")
                                            self.bagObjecten.extend(
                                                BAGObjectFabriek.bof.BAGObjectArrayBijXML(mutatienode))
                                        elif stripschema(mutatienode.tag) == 'Origineel':
                                            objs = BAGObjectFabriek.bof.BAGObjectArrayBijXML(mutatienode)
                                            if len(objs) > 0:
                                                origineelObj = objs[0]
                                        elif stripschema(mutatienode.tag) == 'Wijziging':
                                            objs = BAGObjectFabriek.bof.BAGObjectArrayBijXML(mutatienode)

                                            if len(objs) > 0:
                                                nieuwObj = objs[0]
                                                if nieuwObj and origineelObj:
                                                    nieuwObj.origineelObj = origineelObj
                                                    self.bagObjecten.append(nieuwObj)
                                                    # Log.log.info("Wijziging Object")
                                                    origineelObj = None
                                                    nieuwObj = None

                            bericht = Log.log.endTimer("objCreate (mutaties) - objs=" + str(len(self.bagObjecten)))
                            Database().log_actie('create_objects', 'idem', bericht)

        elif stripschema(node.tag) == 'BAG-Extract-Levering':
            # Meta data: info over levering

            # Sla hele file op
            self.database.log_meta("levering_xml", etree.tostring(node, pretty_print=True))

            # Extraheer BAG lever datum
            #            <v202:LVC-Extract>
            #                <v202:gegVarLevenscyclus>true</v202:gegVarLevenscyclus>
            #                <v202:productcode>DNLDLXAE02</v202:productcode>
            #                <v202:StandTechnischeDatum>20120308</v202:StandTechnischeDatum>
            #            </v202:LVC-Extract>
            node = stripNS(node)
            # Probeer BAG extract datum uit XML te vinden
            extract_datum = node.xpath("//LVC-Extract/StandTechnischeDatum/text()")
            if len(extract_datum) > 0:
                # Gevonden !
                extract_datum = str(extract_datum[0])
            else:
                extract_datum = "onbekend"

            # Opslaan als meta info
            self.database.log_meta("extract_datum", extract_datum)

        else:
            bericht = Log.log.info("Niet-verwerkbare XML node: " + stripschema(node.tag))
            Database().log_actie('n.v.t', 'n.v.t', bericht)

            return

        Log.log.startTimer("dbStart mode = " + mode)
        # Experimenteel: dbStoreCopy() gebruikt COPY ipv INSERT
        # maar moet nog gefinetuned
        if mode == 'Mutatie':
            # Voor mutaties voorlopig nog even ouderwetse INSERT/UPDATE
            # Hier speelt performance ook niet zo'n rol als bij hele BAG inlezen...
            bericht = self.dbStoreInsert(mode)
        else:
            bericht = self.dbStoreCopy(mode)

        Database().log_actie('insert_database', 'idem', bericht)


    def dbStoreInsert(self, mode):

        self.database.verbind()
        rels = 0
        wijzigingen = 0
        for bagObject in self.bagObjecten:
            if bagObject.origineelObj:
                # Mutatie: wijziging
                bagObject.maakUpdateSQL()
                wijzigingen += 1
            else:
                # Mutatie: nieuw object
                bagObject.maakInsertSQL()
            try:
                self.database.uitvoeren(bagObject.sql, bagObject.inhoud)
            except (Exception), e:
                # Heeft geen zin om door te gaan
                Log.log.error("database fout bij insert, ik stop met dit bestand")
                break

            for relatie in bagObject.relaties:
                i = 0
                for sql in relatie.sql:
                    self.database.uitvoeren(sql, relatie.inhoud[i])
                    i += 1
                    rels += 1

        self.database.connection.commit()
        bericht = Log.log.endTimer("dbEnd - nieuw=" + str(len(self.bagObjecten) - wijzigingen) + " gewijzigd=" + str(wijzigingen) + " rels=" + str(rels))
        Log.log.info("------")
        return bericht

    # Experimenteel: inlezen via COPY ipv INSERT: fikse snelheidswinst
    def dbStoreCopy(self, mode):
        try:
            from cStringIO import StringIO
            Log.log.info("running with cStringIO")
        except:
            from StringIO import StringIO
            Log.log.info("running with StringIO")

        import codecs
        Log.log.startTimer("dbStart mode = " + mode)
        self.database.verbind()

        # BAG Objecten en Relaties hebben verschillende tabellen/kolommen
        # Houd deze bij in dictionaries
        # TODO: maak 1 object voor combinatie buffer/kolommen
        buffers = {}
        columns = {}
        rels = 0
        wijzigingen = 0
        for bagObject in self.bagObjecten:
            if bagObject.origineelObj:
                # Mutatie: wijziging, doe nog even traditioneel want heeft wat SQL logica
                bagObject.maakUpdateSQL()
                wijzigingen += 1
                self.database.uitvoeren(bagObject.sql, bagObject.inhoud)
            else:
                # Maak buffer eenmalig aan per tabel
                if bagObject.naam() not in buffers:
                    buffer = StringIO()
                    # cStringIO heeft niet standaard UTF-8 support en BAG is in UTF-8
                    bufferUTF8 = codecs.getwriter("utf8")(buffer)

                    buffers[bagObject.naam()] = bufferUTF8

                # Voeg de inhoud aan buffer toe
                bagObject.maakCopySQL(buffers[bagObject.naam()])

                # Kolom namen
                # TODO dit hoeft natuurlijk maar 1x
                columns[bagObject.naam()] = bagObject.velden

            for relatie in bagObject.relaties:
                # Maak buffer eenmalig aan per relatietabel
                if relatie.relatieNaam() not in buffers:
                    buffer = StringIO()

                    # cStringIO heeft niet standaard UTF-8 support en BAG is in UTF-8
                    bufferUTF8 = codecs.getwriter("utf8")(buffer)
                    buffers[relatie.relatieNaam()] = bufferUTF8

                buffers[relatie.relatieNaam()].write(relatie.sql)
                # Kolom namen
                # TODO dit hoeft natuurlijk maar 1x
                columns[relatie.relatieNaam()] = relatie.velden
                rels += 1

        # Doe DB COPY operaties
        for table in buffers:
            buf = buffers[table]
            buf.seek(0)
            self.database.cursor.copy_from(buf, table, sep='~', null='\\\N', columns=columns[table])

            buf.close()

        self.database.connection.commit()
        bericht = Log.log.endTimer("dbEnd - nieuw=" + str(len(self.bagObjecten) - wijzigingen) + " gewijzigd=" + str(wijzigingen) + " rels=" + str(rels))
        Log.log.info("------")
        return bericht


# TODO mogelijke versnelling met StringIO en concatenatie met COPY ipv INSERT
# http://stackoverflow.com/questions/8144002/use-binary-copy-table-from-with-psycopg2/8150329#8150329
# ## Find the best implementation available on this platform
#try:
#    from cStringIO import StringIO
#    print("running with cStringIO")
#except:
#    from StringIO import StringIO
#    print("running with StringIO")
#
## Writing to a buffer
#output = StringIO()
#output.write('This goes into the buffer. ')
#print >>output, 'And so does this.'
#
## Retrieve the value written
#print output.getvalue()
#
#output.close() # discard buffer memory
#
## Initialize a read buffer
#input = StringIO('Inital value for read buffer')
#
## Read from the buffer
#print input.read()
#
