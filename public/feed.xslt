<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml">

	<xsl:output method="html" encoding="utf-8" indent="yes" /> 

  <xsl:template match="/">
    <html>
      <head>
        <title>XML Viewer</title>
        <link rel="stylesheet" type="text/css" href="/feed-style.css" />
      </head>
      <body>
        <div id="main">
          <xsl:apply-templates/>
        </div>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="*">
    <div class="indent">
      <span class="markup">&lt;</span>
      <span class="start-tag"><xsl:value-of select="local-name(.)"/></span>
      <xsl:apply-templates select="@*" />
      <span class="markup">/&gt;</span>
    </div>
  </xsl:template>

  <xsl:template match="*[node()]">
    <div class="indent">
      <span class="markup">&lt;</span>
      <span class="start-tag"><xsl:value-of select="local-name(.)"/></span>
      <xsl:apply-templates select="@*"/>
      <span class="markup">&gt;</span>

      <span class="text"><xsl:apply-templates/></span>

      <span class="markup">&lt;/</span>
      <span class="end-tag"><xsl:value-of select="local-name(.)"/></span>
      <span class="markup">&gt;</span>
    </div>
  </xsl:template>

  <xsl:template match="@href">
    <xsl:text> </xsl:text>
    <span class="attribute-name"><xsl:value-of select="local-name(.)"/></span>
    <span class="markup">=</span>
    <span class="attribute-quote">"</span><span class="attribute-value"><a href="{.}"><xsl:value-of select="."/></a></span><span class="attribute-quote">"</span>
  </xsl:template>

  <xsl:template match="@*">
    <xsl:text> </xsl:text>
    <span class="attribute-name"><xsl:value-of select="name(.)"/></span>
    <span class="markup">=</span>
    <span class="attribute-quote">"</span><span class="attribute-value"><xsl:value-of select="."/></span><span class="attribute-quote">"</span>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:if test="normalize-space(.)">
      <div class="indent text"><xsl:value-of select="."/></div>
    </xsl:if>
  </xsl:template>

  <xsl:template match="processing-instruction()|comment()">
    <xsl:apply-templates/>
  </xsl:template>
</xsl:stylesheet>
