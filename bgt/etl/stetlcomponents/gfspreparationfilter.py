# -*- coding: utf-8 -*-
#
# Filter that prepares a GFS file which can be used to load with ogr2ogr.
#
# Author: Frank Steggink

import os
import re
import subprocess

from stetl.component import Config
from stetl.filter import Filter
from stetl.packet import FORMAT
from stetl.util import Util, etree
from string import Template

log = Util.get_log("gfspreparationfilter")


class GfsPreparationFilter(Filter):
    """
    This filter prepares a GFS file, so any GML data will be loaded optimally with ogr2ogr. This is done by limiting the
    input GFS to only the feature types which actually occur in the data, and by adding feature count elements.
    """

    XSLT_TEMPLATE = """<?xml version="1.0" encoding="UTF-8"?>
      <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes" omit-xml-declaration="yes"/>
        <xsl:strip-space elements="*"/>
        <xsl:template match="/ | @* | node()">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" />
            </xsl:copy>
        </xsl:template>
        <xsl:template match="GMLFeatureClass">
            <!-- Filter on particular element -->
            <xsl:if test="ElementPath/text()='$elemtype'">
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()" />
                </xsl:copy>
            </xsl:if>
        </xsl:template>
        <xsl:template match="DatasetSpecificInfo">
            <xsl:copy>
                <!-- Add feature count -->
                <FeatureCount>$featurecount</FeatureCount>
                <xsl:apply-templates select="@* | node()" />
            </xsl:copy>
        </xsl:template>
      </xsl:stylesheet>
    """

    # Start attribute config meta
    # Applying Decorator pattern with the Config class to provide
    # read-only config values from the configured properties.

    @Config(ptype=str, default=None, required=True)
    def input_gfs(self):
        """
        Name of the original GFS file.
        """
        pass

    @Config(ptype=str, default=None, required=False)
    def output_gfs(self):
        """
        Name of the GFS file which will be generated. If not present, it will be derived from the GML file name in the
        packet data.
        """
        pass

    # End attribute config meta

    # Constructor
    def __init__(self, configdict, section, consumes=FORMAT.string, produces=FORMAT.string):
        Filter.__init__(self, configdict, section, consumes, produces)

    def init(self):
        log.info('Init: GFS preparation filter')
        if self.input_gfs is None:
            # If no input_gfs is present:
            err_s = 'The input_gfs needs to be configured'
            log.error(err_s)
            raise ValueError('The input_gfs needs to be configured')

    def exit(self):
        log.info('Exit: GFS preparation filter')

    def invoke(self, packet):
        input_gml = packet.data
        if input_gml is None:
            return packet

        log.info('start preparing GFS')

        # TODO: consider using a Stetl chain for these steps

        # Steps:
        # 1. Call ogrinfo and capture its output.
        log.info('calling ogrinfo')
        output_ogrinfo = self.execute_ogrinfo(input_gml)

        # 2. Parse the output from ogrinfo, result will be a list of feature names and counts.
        # TODO: check if the feature types and counts in files with multiple feature types are captured correctly.
        # This will be necessary for TOP10NL.
        log.info('parsing ogrinfo output')
        subst_dict = self.parse_ogrinfo_output(output_ogrinfo)

        # 3. Prepare the XSLT used for the tranformation. Substitute the element types and feature counts.
        log.info('preparing XSLT template')
        formatted_xslt = self.prepare_xslt_template(subst_dict)

        # 4. Transform the input_gfs with the prepared XSLT.
        log.info('transforming input GFS')
        result = self.transform_input_gfs(formatted_xslt)

        # 5. Save the output_gfs.
        log.info('writing output GFS')

        if self.output_gfs is not None:
            gfs_path = self.output_gfs
        else:
            file_ext = os.path.splitext(input_gml)
            gfs_path = file_ext[0] + '.gfs'

        with open(gfs_path, 'w') as f:
            f.write(result)

        log.info('preparing GFS done')

        # Return the original packet, since this contains the name of the GML file which is being loaded
        return packet

    def execute_ogrinfo(self, gml_file):
        ogrinfo_cmd = 'ogrinfo -ro -al -so %s' % gml_file

        use_shell = True
        if os.name == 'nt':
            use_shell = False

        result = subprocess.check_output(ogrinfo_cmd, shell=use_shell)
        return result

    def parse_ogrinfo_output(self, output_ogrinfo):
        pattern = re.compile('.*Layer name: (\w+:)?(?P<elemtype>\w+).*Feature Count: (?P<featurecount>[0-9]+).*', re.S)
        m = pattern.match(output_ogrinfo)
        if m is not None:
            subst_dict = m.groupdict()
        else:
            subst_dict = {'elemtype': '_nlextract_dummy_', 'featurecount': '0'}

        return subst_dict

    def prepare_xslt_template(self, subst_dict):
        template = Template(self.XSLT_TEMPLATE)
        formatted_xslt = template.safe_substitute(subst_dict)

        return formatted_xslt

    def transform_input_gfs(self, formatted_xslt):
        xslt_doc = etree.fromstring(formatted_xslt)
        xslt_obj = etree.XSLT(xslt_doc)
        xml_doc = etree.parse(self.input_gfs)
        result = xslt_obj(xml_doc)

        return str(result)