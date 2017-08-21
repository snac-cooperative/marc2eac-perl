<?xml version="1.0" encoding="UTF-8"?>
<!-- Edited with emacs -->
<!-- New Namespace -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" version="4.0" standalone="yes" indent="yes"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
    encoding="UTF-8" />

  <xsl:variable name="imageDir" select="string('/identities/images')"/>
  <xsl:variable name="WCatPointers" select="true()"/>
  <xsl:variable name="Environment" select="string('prod')"/>

  <xsl:template match="/nameAuthorities">
    <xsl:choose>
      <xsl:when test="@hitCount = 1">
        <head>
          <meta http-equiv="REFRESH" content="0; URL={match/uri}"/>
          </head>
        </xsl:when>
      <xsl:otherwise>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
          <script type="text/javascript" src="/identities/NameFinderResults.js"></script>
          <link href="/identities/identities.css" rel="stylesheet" type="text/css" />
          <style type="text/css">
#maincol {
position:relative;
margin:0;
padding:10px;
}
            .iconPad {padding:0px 10px 0px 10px;}
            zhtml body  {height:100%;}
            #content {height:100%;padding-bottom:40px;}

            #colWrapper {
              height:100%;
            }

            #leftColumn {
              position: relative;
              margin-right: 350px;
            }

            #leftContent {
              background: #fff;
              height:100%
            }


            #rightColumn {
position:relative;
              width: 350px;
              float: right;
            }

            #rightColumn h2 {margin:10px 0px 10px 0px;font-weight:bold;}
            #rightColumn p {margin:5px 5px 5px 0px;line-height:1.5;font-size:1.2em;}
            #rightColumn form {padding:20px 0px 10px 0px;}
            #rightColumn input {padding:2px;font-weight:bold;}

            .clearing {
              
              clear: both;
            }


            div#search-edit-wrap {}

            div#search-form-edit {border:1px solid #ccc;vertical-align:middle;
            margin:10px;padding:10px;background:#eee;font-size:1em;}

            div#search-form-edit form {vertical-align:middle;text-align:center;background:#eee;}
            div#search-form-edit form label {font-weight:bold;font-size:1.5em;margin-right:5px;vertical-align:middle;}
            #search-form-edit input[type=text] {padding:2px;font-size:10px;}
            </style>
          <title>WorldCat Identities</title>
          </head>
        <body>
            <!-- masthead -->
            <div id="masthead">
              <img id="wc-brand-project-title" src="{$imageDir}/masthead_wcident_en.gif" alt="WorldCat Identities" />
            <xsl:if test="$Environment='dev' or $Environment='research'">
              <div id="search-form">
                <form method="get" action="/identities/find">
                  <label>Name:</label>
                  <input size="35" name="fullName" type="text"/>
                  <input class="btnNavSearch" value="Go" type="submit"/>
                  </form>
                </div>
              </xsl:if>
              </div><!-- close Div Masthead -->
          <div id="content">
              <div id="rightColumn">
                <xsl:call-template name="ResultsKey"/>
                <xsl:if test="contains($Environment, 'dev')">
                  <xsl:call-template name="mergeBox"/>
                  </xsl:if>
                </div> <!-- rightcol -->
          <div id="leftColumn">
            <div id="searchResults">
              <div id="resultsList">
                <h2>
                  <xsl:choose>
                    <xsl:when test="@hitCount='0'">
                      <xsl:text>No Matches found for </xsl:text>
                      <em>
                        <xsl:text>&apos;</xsl:text>
                        <xsl:value-of select="@query" />
                        <xsl:text>&apos;</xsl:text>
                        </em>
                      </xsl:when>
                    <xsl:when test="@matchType='phrase' and @hitCount='1'">
                      <xsl:text>Phrase (Auto-)Match for &apos;</xsl:text>
                      <xsl:value-of select="@query" /><xsl:text>&apos;</xsl:text>
                      </xsl:when>
                    <xsl:when test="@matchType='phrase'">
                      <xsl:text>Phrase Matches for &apos;</xsl:text>
                      <xsl:value-of select="@query" />
                      <xsl:text>&apos; (</xsl:text>
                      <xsl:value-of select="count(match)" />
                      <xsl:text> of </xsl:text>
                      <xsl:value-of select="@hitCount" />
                      <xsl:text>)</xsl:text>
                      </xsl:when>
                    <xsl:when test="@matchType">
                      <xsl:text>Word Matches for &apos;</xsl:text>
                      <xsl:value-of select="@query" />
                      <xsl:text>&apos; (</xsl:text>
                      <xsl:value-of select="count(match)" />
                      <xsl:text> of </xsl:text>
                      <xsl:value-of select="@hitCount" />
                      <xsl:text>)</xsl:text>
                      </xsl:when>
                    <xsl:when test="@status='error'">
                      <xsl:value-of select="." />
                      </xsl:when>
                    <xsl:otherwise>
                      <xsl:text>Matches for </xsl:text>
                      <em>
                        <xsl:text>&apos;</xsl:text>
                        <xsl:value-of select="@query" />
                        <xsl:text>&apos;</xsl:text>
                        </em>
                      </xsl:otherwise>
                    </xsl:choose>
                  </h2>
                <div id="resultsKeyHider" style="display:none;">
                  <div id="shortResultsKeyWrapper">
                    <div id="shortResultsKey">
                      <h3>Results Key:</h3>
                      <div>
                        <span>
                          <img alt="Icon for a Personal, Uncontrolled Identity" src="{$imageDir}/person.gif"/>
                          A Personal Identity
                          </span>
                        <br/>
                        <span>
                          <img alt="Icon for a Personal, Controlled Identity" src="{$imageDir}/person-orange.gif"/>
                          A Personal Identity from a controlled vocabulary
                          </span>
                        </div>
                      <div>
                        <span>
                          <img alt="Icon for a Corporate, Uncontrolled Identity" src="{$imageDir}/corp.gif"/>
                          A Corporate Identity
                          </span>
                        <br/>
                        <span>
                          <img alt="Icon for a Corporate, Controlled Identity" src="{$imageDir}/corp-orange.gif"/>
                          A Corporate Identity from a controlled vocabulary
                          </span>
                        </div>
                      </div><!-- close shortResultsKey -->
                    </div><!-- close shortResultsKeyWrapper -->
                  </div><!-- close resultsKeyHider -->
                <ol class="resultsList">
                  <xsl:choose>
                    <xsl:when test="@hitCount=0">
                      <div id="bogus">&#160;</div>
                      </xsl:when>
                    <xsl:when test="not(@status='error')">
                      <xsl:apply-templates />
                      </xsl:when>
                    </xsl:choose>
                  </ol>
                </div> <!-- resultsList -->
              </div> <!-- searchResults -->
            </div> <!-- leftcol -->
            </div> <!-- content -->

          <div id="footer">
            <table border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td>
                  <a href="http://www.oclc.org/policies/copyright/default.htm">
                     &#169; 2010 OCLC Online Computer Library Center, Inc. &#160;
                     </a>
                  <br />WorldCat Identities is covered by the
                  <a href="http://www.oclc.org/research/researchworks/terms.htm">
                    OCLC ResearchWorks Terms and Conditions</a>
                  <br/>OCLC 6565 Kilgour Place, Dublin OH USA 43017
                  </td>
                <td style="text-align:right;vertical-align:middle;">
                  Project Page
                  <span class="divider">|</span>
                  <a href="http://www.oclc.org/programsandresearch/feedback/form.asp?project=WC-IDs"
                    target="_blank">
                    Feedback
                    </a>
                  <span class="divider">|</span>
                  Known Problems
                  </td>
                </tr>
              </table>	
            </div><!-- close footer -->
          </body>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>

  <xsl:template match="phraseMatches">
    <xsl:if test="@hitCount>0">
      <tr>
        <th>
          Phrase Matches (<xsl:value-of select="count(match)" /> of <xsl:value-of select="@hitCount" />)
          </th>
        </tr>
      <xsl:apply-templates />
      </xsl:if>
    </xsl:template>

  <xsl:template match="wordMatches">
    <xsl:if test="@hitCount>0">
      <tr>
        <th>
          Word Matches (
          <xsl:value-of select="count(match)" />
          of
          <xsl:value-of select="@hitCount" />)
          </th>
        </tr>
      <xsl:apply-templates />
      </xsl:if>
    </xsl:template>

  <xsl:template match="match">
    <xsl:variable name="url">
      <xsl:choose>
        <xsl:when test="contains(uri, 'http://errol.oclc.org/laf/')">
          <xsl:value-of select="uri"/>.html
          </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="uri"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
    <xsl:variable name="fontSize">
      <xsl:choose>
        <xsl:when test="@usage>10000">2.0</xsl:when>
        <xsl:when test="@usage>5000">1.8</xsl:when>
        <xsl:when test="@usage>1000">1.6</xsl:when>
        <xsl:when test="@usage>500">1.4</xsl:when>
        <xsl:when test="@usage>10">1.2</xsl:when>
        <xsl:otherwise>1.0</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
    <li>
      <xsl:choose>
        <!--xsl:when test="nameType = 'personal' and lccn"-->
        <xsl:when test="nameType = 'personal' and starts-with(key, 'lccn')">
          <img src="{$imageDir}/person-orange.gif" class="iconPad"
               alt="Controlled Personal Identity" title="Controlled Personal Identity"/>
          </xsl:when>
        <xsl:when test="nameType = 'personal' and starts-with(key, 'viaf')">
          <img src="{$imageDir}/person-orange.gif" class="iconPad"
               alt="Controlled Personal Identity" title="Controlled Personal Identity"/>
          </xsl:when>
        <xsl:when test="nameType = 'personal'">
          <img src="{$imageDir}/person.gif" class="iconPad"
               alt="Personal Identity" title="Personal Identity"/>
          </xsl:when>
        <xsl:when test="nameType = 'corporate' and lccn">
          <img src="{$imageDir}/corp-orange.gif" class="iconPad"
               alt="Controlled Corporate Identity" title="Controlled Corporate Identity"/>
          </xsl:when>
        <xsl:when test="nameType = 'corporate' and starts-with(key, 'viaf')">
          <img src="{$imageDir}/corp-orange.gif" class="iconPad"
               alt="Controlled Corporate Identity" title="Controlled Corporate Identity"/>
          </xsl:when>
        <xsl:otherwise>
          <img src="{$imageDir}/corp.gif" class="iconPad"
               alt="Corporate Identity" title="Corporate Identity"/>
          </xsl:otherwise>
        </xsl:choose>
      <span style="FONT-SIZE: {$fontSize}em">
        <a href="{$url}" title="{citation}">
          <xsl:value-of select="establishedForm"/>
          </a><input type="hidden" name="{key}" value="{@usage}"/>
        <xsl:choose>
          <xsl:when test="dates"></xsl:when>
          <xsl:when test="pubDates"> published: <xsl:value-of select="pubDates"/></xsl:when>
          </xsl:choose>
        <xsl:choose>
          <xsl:when test="subjectHeading"> (<xsl:value-of select="subjectHeading"/>)</xsl:when>
          <xsl:when test="genre"> (<xsl:value-of select="genre"/>)</xsl:when>
          </xsl:choose>
        </span>
      </li>
    </xsl:template>

  <xsl:template name="ResultsKey">
      <div class="col-right-entry">
    <div id="resultsKey">
      <div class="resultsKeyContent">
      <h3 class="col-right-title">Results Key</h3>
        <span class="display-block">
          <img src="{$imageDir}/person.gif"
               alt="Icon for a Personal, Uncontrolled Identity"/>
          A Personal Identity
          </span>
        <span class="display-block">
          <img src="{$imageDir}/person-orange.gif"
               alt="Icon for a Personal, Controlled Identity"/>
          A Personal Identity from a controlled vocabulary
          </span>
        <span class="display-block">
          <img src="{$imageDir}/corp.gif"
               alt="Icon for a Corporate, Uncontrolled Identity"/>
          A Corporate Identity
          </span>
        <span class="display-block">
          <img src="{$imageDir}/corp-orange.gif"
               alt="Icon for a Corporate, Controlled Identity"/>
          A Corporate Identity from a controlled vocabulary
          </span>

        <p>
          <strong>Text Size</strong>
          indicates relative popularity of an Identity
          </p>

        <p>
          <strong>(Subject)</strong>
          The information in parentheses indicate the Subject Heading associated with that Identity
          </p>
        </div> <!-- resultsKeyContent -->
      </div> <!-- resultsKey -->
        </div> <!-- col-right-entry -->
    </xsl:template>

  <xsl:template name="mergeBox">
    <div class="col-right-entry">
      <div id="merge">
        <div class="resultsKeyContent">
          <h3 class="col-right-title">Edit Identity Records</h3>
          <p>
            To begin the Identity Merge process, please click on the "Merge Identities"
            button below.
            </p>
          <p>
            You will be given the opportunity to select and search for
            Identity Records that need to be combined.
            </p>
          <form action="merge.html" method="get">
            <input type="hidden" name="fullName" value="{@query}"/>
            <input value="Merge Identities" type="submit"/>
            </form>
          </div> <!-- resultsKeyContent -->
        </div><!-- merge -->
      </div> <!-- col-right-entry -->
    </xsl:template>
  </xsl:stylesheet>