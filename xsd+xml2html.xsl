<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:exsl="http://exslt.org/common" xmlns:dyn="http://exslt.org/dynamic">
	<!-- MIT License

	Copyright (c) 2017 Michiel Meulendijk
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE. -->
	
	<xsl:strip-space elements="*"/>
	
	<!-- set method as either html or xhtml. Note: if you want to process the results
	with html2xml.xsl, you need to use xhtml. Note 2: browsers won't display the form correctly if
	it does not contain a valid XHTML doctype and if it is not served with content type application/xhtml+xml -->
	<!-- <xsl:output method="xhtml" omit-xml-declaration="no" /> -->
	<xsl:output method="html" omit-xml-declaration="yes" indent="no" />
	
	<!-- choose the JavaScript (js) or XSLT (xslt) option for processing the form results -->
	<!-- <xsl:variable name="config-to-xml">xslt</xsl:variable> -->
	<xsl:variable name="config-xml-generator">xslt</xsl:variable>
	
	<!-- choose a JavaScript function to be called when the form is submitted.
	it should accept a string argument containing the xml or html -->
	<xsl:variable name="config-js-callback">console.log</xsl:variable>
	
	<!-- optionally specify a css stylesheet to use for the form.
	it will be inserted as a link tag inside the form element. -->
	<xsl:variable name="config-css">style.css</xsl:variable>
	
	<!-- optionally specify the xml document to populate the form with -->
	<xsl:variable name="xml-doc">
		<xsl:copy-of select="document('D:\Michiel\Workspaces\Eclipse\thack\src\main\resources\complex-sample.xml')/*"/>
	</xsl:variable>
	
	<!-- override default matching template -->
	<xsl:template match="*"/>
	
	<!-- root match from which all other templates are invoked -->
	<xsl:template match="/xs:schema">
		<xsl:message><xsl:value-of select="exsl:node-set($xml-doc)/*" /></xsl:message>
		
		<xsl:element name="form">
			<xsl:attribute name="action">javascript:void(0);</xsl:attribute>
			
			<xsl:if test="$config-xml-generator='js'">
				<xsl:attribute name="onsubmit">
					<xsl:value-of select="$config-js-callback" />(getXML(this));
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if test="$config-xml-generator='xslt'">
				<xsl:attribute name="onsubmit">
					<xsl:value-of select="$config-js-callback" />(this.outerHTML);
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if test="$config-css">
				<xsl:element name="link">
					<xsl:attribute name="rel">stylesheet</xsl:attribute>
					<xsl:attribute name="type">text/css</xsl:attribute>
					<xsl:attribute name="href">
						<xsl:value-of select="$config-css" />
					</xsl:attribute>
				</xsl:element>
			</xsl:if>
			
			<xsl:apply-templates select="xs:element" />
			
			<xsl:element name="input">
				<xsl:attribute name="type">submit</xsl:attribute>
				<xsl:attribute name="value">OK</xsl:attribute>
			</xsl:element>
			
			<xsl:element name="script">
				<xsl:attribute name="type">text/javascript</xsl:attribute>
				<xsl:text disable-output-escaping="yes">for (var i=0; i&lt;document.querySelectorAll("[data-xsd2form-filled]").length; i++) { if (document.querySelectorAll("[data-xsd2form-filled]")[i].closest("[data-xsd2form-choice]")) document.querySelectorAll("[data-xsd2form-filled]")[i].closest("[data-xsd2form-choice]").previousElementSibling.querySelector("input[type='radio']").setAttribute("checked","checked"); }</xsl:text>
			</xsl:element>
			
			<xsl:variable name="code"></xsl:variable>
			
			<xsl:element name="script">
				<xsl:attribute name="type">text/javascript</xsl:attribute>
				<xsl:text disable-output-escaping="yes">var htmlToXML = function(root) {
					return "&lt;?xml version=\"1.0\"?&gt;".concat(getXML(root));
				}
				
				var getXML = function(parent, attributesOnly) {
					var xml = "";
					for (var i=0; i&lt;parent.children.length; i++) {
						if (!parent.children[i].getAttribute("style")) {
							switch (parent.children[i].getAttribute("data-xsd2form-type")) {
								case "element":
									if (!attributesOnly)
										xml = xml.concat("&lt;")
											.concat(parent.children[i].getAttribute("data-xsd2form-name"))
											.concat(getXML(parent.children[i], true))
											.concat(">")
											.concat(function() {
												if (parent.children[i].nodeName.toLowerCase() === "label") {
													return getContent(parent.children[i]);
												} else return getXML(parent.children[i])
											}())
											.concat("&lt;/")
											.concat(parent.children[i].getAttribute("data-xsd2form-name"))
											.concat("&gt;");
										break;
								case "attribute":
									if (attributesOnly)
										xml = xml.concat(" ")
											.concat(parent.children[i].getAttribute("data-xsd2form-name"))
											.concat("=\"")
											.concat(getContent(parent.children[i]))
											.concat("\"");
									break;
								case "cdata":
									if (!attributesOnly)
										xml = xml
											.concat(getContent(parent.children[i]));
									break;
								default:
									if (!attributesOnly)
										if (!parent.children[i].getAttribute("data-xsd2form-choice") || (parent.children[i].getAttribute("data-xsd2form-choice") &amp;&amp; parent.children[i].previousElementSibling.getElementsByTagName("input")[0].checked))
											xml = xml.concat(getXML(parent.children[i]));
									break;
							}
						}
					}
					return xml;
				}
				
				var getContent = function(node) {
					if (node.getElementsByTagName("input").length > 0) {
						switch(node.getElementsByTagName("input")[0].getAttribute("type").toLowerCase()) {
							case "checkbox":
								return node.getElementsByTagName("input")[0].checked;
							default:
								return node.getElementsByTagName("input")[0].value;
						}
					} else if (node.getElementsByTagName("select").length > 0) {
						return node.getElementsByTagName("select")[0].value;
					}
				}</xsl:text>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	
	<!-- handle elements with type attribute; determine if they're complex or simple and process them accordingly -->
	<xsl:template match="xs:element[@type]">
		<xsl:param name="choice" select="false" />
		<xsl:param name="tree" />
		
		<xsl:variable name="type">
			<xsl:value-of select="@type"/>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="//xs:complexType[@name=$type]/xs:simpleContent">
				<xsl:call-template name="handle-complex-elements">
					<xsl:with-param name="simple">true</xsl:with-param>
					<xsl:with-param name="choice" select="$choice"/>
					<xsl:with-param name="tree" select="$tree" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="//xs:complexType[@name=$type]">
				<xsl:call-template name="handle-complex-elements">
					<xsl:with-param name="simple">false</xsl:with-param>
					<xsl:with-param name="choice" select="$choice"/>
					<xsl:with-param name="tree" select="$tree" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="//xs:simpleType[@name=$type]">
				<xsl:call-template name="handle-simple-elements">
					<xsl:with-param name="choice" select="$choice"/>
					<xsl:with-param name="tree" select="$tree" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="starts-with($type, 'xs:')">
				<xsl:call-template name="handle-simple-elements">
					<xsl:with-param name="choice" select="$choice"/>
					<xsl:with-param name="tree" select="$tree" />
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<!-- handle complex elements with simple content -->
	<xsl:template match="xs:element[xs:complexType/xs:simpleContent]">
		<xsl:param name="choice" select="false" />
		<xsl:param name="tree" />
		
		<xsl:call-template name="handle-complex-elements">
			<xsl:with-param name="simple">true</xsl:with-param>
			<xsl:with-param name="choice" select="$choice"/>
			<xsl:with-param name="tree" select="$tree" />
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="xs:group[@ref]">
		<xsl:param name="tree" />
		
		<xsl:call-template name="handle-complex-elements">
			<xsl:with-param name="id" select="@ref" />
			<xsl:with-param name="simple" select="false" />
			<xsl:with-param name="tree" select="$tree" />
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="xs:attributeGroup[@ref]">
		<xsl:param name="tree" />
		
		<xsl:variable name="ref" select="@ref" />
		<xsl:apply-templates select="//xs:attributeGroup[@name=$ref]/xs:attribute">
			<xsl:with-param name="id" select="@ref" />
			<xsl:with-param name="tree" select="$tree" />
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- handle complex elements, which optionally contain simple content -->
	<!-- handle minOccurs and maxOccurs, calls handle-complex-element for further processing -->
	<xsl:template name="handle-complex-elements" match="xs:element[xs:complexType/*[not(self::xs:simpleContent)]]">
		<xsl:param name="id" select="@name" />
		<xsl:param name="simple"/>
		<xsl:param name="choice" select="false" />
		<xsl:param name="tree" />
		
		<xsl:if test="$choice != 'false'">
			<xsl:call-template name="add-choice-button">
				<xsl:with-param name="name" select="$choice" />
				<xsl:with-param name="description">
					<xsl:call-template name="get-description" />
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:element name="section">
			<xsl:if test="$choice != 'false'">
				<xsl:attribute name="data-xsd2form-choice">true</xsl:attribute>
			</xsl:if>
			
			<xsl:call-template name="handle-complex-element">
				<xsl:with-param name="id" select="$id" />
				<xsl:with-param name="description">
					<xsl:call-template name="get-description" />
				</xsl:with-param>
				<xsl:with-param name="simple" select="$simple" />
				<xsl:with-param name="count">
					<xsl:choose>
						<xsl:when test="@minOccurs">
							<xsl:choose>
								<xsl:when test="count(dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'/',$id))) &gt; @minOccurs">
									<xsl:value-of select="count(dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'/',$id)))" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="@minOccurs" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>1</xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>
				<xsl:with-param name="index">1</xsl:with-param>
				<xsl:with-param name="tree" select="concat($tree,'/',$id)" />
			</xsl:call-template>
			
			<xsl:if test="(@minOccurs or @maxOccurs) and not(@minOccurs = @maxOccurs)">
				<xsl:call-template name="handle-complex-element">
					<xsl:with-param name="id" select="$id"/>
					<xsl:with-param name="description">
						<xsl:call-template name="get-description" />
					</xsl:with-param>
					<xsl:with-param name="simple" select="$simple" />
					<xsl:with-param name="count">1</xsl:with-param>
					<xsl:with-param name="index">0</xsl:with-param>
					<xsl:with-param name="invisible" select="'true'" />
					<xsl:with-param name="tree" select="concat($tree,'/',$id)" />
				</xsl:call-template>
				
				<xsl:call-template name="add-add-button">
					<xsl:with-param name="description">
						<xsl:call-template name="get-description" />
					</xsl:with-param>
				</xsl:call-template>
			</xsl:if>
		</xsl:element>
	</xsl:template>
	
	<!-- handle complex element -->
	<xsl:template name="handle-complex-element">
		<xsl:param name="id" select="@name" />
		<xsl:param name="description" />
		<xsl:param name="count" select="1"/>
		<xsl:param name="index" />
		<xsl:param name="simple"/>
		<xsl:param name="invisible" select="'false'"/>
		<xsl:param name="tree" />
		
		<xsl:if test="$count > 0">
			<xsl:element name="fieldset">
				<xsl:attribute name="data-xsd2form-type">
					<xsl:value-of select="local-name()" />
				</xsl:attribute>
				<xsl:attribute name="data-xsd2form-name">
					<xsl:value-of select="@name" />
				</xsl:attribute>
				
				<xsl:if test="$invisible = 'true'">
					<xsl:attribute name="style">display: none;</xsl:attribute>
				</xsl:if>
				
				<xsl:element name="legend">
					<xsl:value-of select="$description" />
					<xsl:call-template name="add-remove-button" />
				</xsl:element>
				
				<xsl:variable name="ref" select="@ref"/>
				<xsl:apply-templates select="xs:complexType/xs:sequence|xs:complexType/xs:all|xs:complexType/xs:choice|xs:complexType/xs:attribute|xs:complexType/xs:attributeGroup|//xs:group[@name=$ref]/*">
					<xsl:with-param name="tree" select="concat($tree,'[',$index,']')" />
				</xsl:apply-templates>
				
				<xsl:choose>
					<xsl:when test="$simple='true'">
						<xsl:call-template name="handle-simple-element">
							<xsl:with-param name="description" select="$description" />
							<xsl:with-param name="no-remove-button">true</xsl:with-param>
							<xsl:with-param name="count">1</xsl:with-param>
							<xsl:with-param name="index">1</xsl:with-param>
							<xsl:with-param name="html-type">cdata</xsl:with-param>
							<xsl:with-param name="tree" select="concat($tree,'[',$index,']')" />
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="*/*/xs:extension/*">
							<xsl:with-param name="tree" select="concat($tree,'[',$index,']')" />
						</xsl:apply-templates>
						<xsl:call-template name="add-extensions-recursively">
							<xsl:with-param name="tree" select="concat($tree,'[',$index,']')" />
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:element>
			
			<xsl:call-template name="handle-complex-element">
				<xsl:with-param name="id" select="$id"/>
				<xsl:with-param name="description" select="$description" />
				<xsl:with-param name="simple" select="$simple"/>
				<xsl:with-param name="count" select="$count - 1"/>
				<xsl:with-param name="index" select="$index + 1"/>
				<xsl:with-param name="tree" select="$tree"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<!-- handle simple elements -->
	<!-- handle minOccurs and maxOccurs, calls handle-simple-element for further processing -->
	<xsl:template name="handle-simple-elements" match="xs:element[xs:simpleType]"> <!-- |xs:element[xs:complexType/xs:simpleContent/xs:restriction]|xs:element[xs:complexType/xs:simpleContent/xs:extension] -->
		<xsl:param name="id" select="@name" />
		<xsl:param name="choice" select="false" />
		<xsl:param name="tree" />
		
		<xsl:if test="$choice != 'false'">
			<xsl:call-template name="add-choice-button">
				<xsl:with-param name="name" select="$choice" />
				<xsl:with-param name="description">
					<xsl:call-template name="get-description" />
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:element name="section">
			<xsl:if test="$choice != 'false'">
				<xsl:attribute name="data-xsd2form-choice">true</xsl:attribute>
			</xsl:if>
			
			<xsl:call-template name="handle-simple-element">
				<xsl:with-param name="id" select="$id" />
				<xsl:with-param name="description">
					<xsl:call-template name="get-description" />
				</xsl:with-param>
				<xsl:with-param name="no-remove-button">false</xsl:with-param>
				<xsl:with-param name="count">
					<xsl:choose>
						<xsl:when test="@minOccurs">
							<xsl:choose>
								<xsl:when test="count(dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'/',@name))) &gt; @minOccurs">
									<xsl:value-of select="count(dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'/',@name)))" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="@minOccurs" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>1</xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>
				<xsl:with-param name="index">1</xsl:with-param>
				<xsl:with-param name="tree" select="concat($tree,'/',@name)" />
			</xsl:call-template>
			
			<xsl:if test="(@minOccurs or @maxOccurs) and not(@minOccurs = @maxOccurs)">
				<xsl:call-template name="handle-simple-element">
					<xsl:with-param name="id" select="$id"/>
					<xsl:with-param name="description">
						<xsl:call-template name="get-description" />
					</xsl:with-param>
					<xsl:with-param name="no-remove-button">false</xsl:with-param>
					<xsl:with-param name="count">1</xsl:with-param>
					<xsl:with-param name="index">0</xsl:with-param>
					<xsl:with-param name="invisible" select="'true'" />
					<xsl:with-param name="tree" select="concat($tree,'/',@name)" />
				</xsl:call-template>
				
				<xsl:call-template name="add-add-button">
					<xsl:with-param name="description">
						<xsl:call-template name="get-description" />
					</xsl:with-param>
				</xsl:call-template>
			</xsl:if>
		</xsl:element>
	</xsl:template>
	
	<!-- handle attribute as simple element, without option for minOccurs or maxOccurs -->
	<xsl:template name="handle-attributes" match="xs:attribute">
		<xsl:param name="tree" />
		
		<xsl:call-template name="handle-simple-element">
			<xsl:with-param name="description">
				<xsl:call-template name="get-description" />
			</xsl:with-param>
			<xsl:with-param name="no-remove-button">true</xsl:with-param>
			<xsl:with-param name="count">1</xsl:with-param>
			<xsl:with-param name="index">1</xsl:with-param>
			<xsl:with-param name="tree" select="concat($tree,'/@',@name)" />
		</xsl:call-template>
	</xsl:template>
	
	<!-- handle simple element -->
	<xsl:template name="handle-simple-element">
		<xsl:param name="id" select="@name" />
		<xsl:param name="description" />
		<xsl:param name="count"/>
		<xsl:param name="index"/>
		<xsl:param name="no-remove-button"/>
		<xsl:param name="invisible" select="'false'"/>
		<xsl:param name="html-type" select="local-name()"/>
		<xsl:param name="tree" />
		
		<xsl:if test="$count > 0">
			<xsl:variable name="type">
				<xsl:call-template name="get-xs-type"/>
			</xsl:variable>
			
			<xsl:element name="label">
				<xsl:attribute name="data-xsd2form-type">
					<xsl:value-of select="$html-type" />
				</xsl:attribute>
				<xsl:attribute name="data-xsd2form-name">
					<xsl:value-of select="@name" />
				</xsl:attribute>
				
				<xsl:if test="$invisible = 'true'">
					<xsl:attribute name="style">display: none;</xsl:attribute>
				</xsl:if>
				
				<xsl:element name="span">
					<xsl:value-of select="$description"/>
					<xsl:if test="not($no-remove-button = 'true')">
						<xsl:call-template name="add-remove-button" />
					</xsl:if>
				</xsl:element>
				
				<xsl:variable name="choice">
					<xsl:call-template name="attr-value">
						<xsl:with-param name="attr">xs:enumeration</xsl:with-param>
					</xsl:call-template>
				</xsl:variable>
				
				<xsl:choose>
					<xsl:when test="not($choice='')">
						<xsl:element name="select">
							<xsl:attribute name="onchange">
								<xsl:text>for (var i=0; i&lt;this.children.length; i++) { this.children[i].removeAttribute("selected"); } this.children[this.selectedIndex].setAttribute("selected","selected");</xsl:text>
							</xsl:attribute>
							
							<xsl:if test="@fixed">
								<xsl:attribute name="disabled">disabled</xsl:attribute>
							</xsl:if>
							
							<xsl:if test="not($invisible = 'true') and not(dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'[',$index,']'))) = ''">
								<xsl:attribute name="data-xsd2form-filled">true</xsl:attribute>
							</xsl:if>
							
							<xsl:call-template name="handle-enumerations">
								<xsl:with-param name="default">
									<xsl:choose>
										<xsl:when test="not($invisible = 'true') and not(dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'[',$index,']'))) = ''">
											<xsl:value-of select="dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'[',$index,']'))" />
										</xsl:when>
										<xsl:when test="@default"><xsl:value-of select="@default" /></xsl:when>
										<xsl:when test="@fixed"><xsl:value-of select="@fixed" /></xsl:when>
									</xsl:choose>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="input">
							<xsl:attribute name="type">
								<xsl:choose>
									<xsl:when test="$type = 'xs:string' or $type = 'xs:token' or $type = 'xs:language'">
										<xsl:text>text</xsl:text>
									</xsl:when>
									<xsl:when test="$type = 'xs:decimal' or $type = 'xs:float' or $type = 'xs:double' or $type = 'xs:integer' or $type = 'xs:byte' or $type = 'xs:int' or $type = 'xs:long' or $type = 'xs:positiveInteger' or $type = 'xs:negativeInteger' or $type = 'xs:nonPositiveInteger' or $type = 'xs:nonNegativeInteger' or $type = 'xs:short' or $type = 'xs:unsignedLong' or $type = 'xs:unsignedInt' or $type = 'xs:unsignedShort' or $type = 'xs:unsignedByte'">
										<xsl:text>number</xsl:text>
									</xsl:when>
									<xsl:when test="$type = 'xs:boolean'">
										<xsl:text>checkbox</xsl:text>
									</xsl:when>
									<xsl:when test="$type = 'xs:dateTime'">
										<xsl:text>datetime</xsl:text>
									</xsl:when>
									<xsl:when test="$type = 'xs:date'">
										<xsl:text>date</xsl:text>
									</xsl:when>
									<xsl:when test="$type = 'xs:time'">
										<xsl:text>time</xsl:text>
									</xsl:when>
									<xsl:when test="$type = 'xs:anyURI'">
										<xsl:text>url</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>text</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							
							<xsl:attribute name="onchange">
								<xsl:choose>
									<xsl:when test="$type = 'xs:boolean'">
										<xsl:text>if (this.checked) { this.setAttribute("checked","checked") } else { this.removeAttribute("checked") }</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>this.setAttribute("value", this.value);</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							
							<xsl:if test="@fixed">
								<xsl:attribute name="readonly">readonly</xsl:attribute>
								<xsl:choose>
									<xsl:when test="$type = 'xs:boolean'">
										<xsl:if test="@fixed = 'true'">
											<xsl:if test="not(dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'[',$index,']')) = 'false')">
												<xsl:attribute name="checked">checked</xsl:attribute>
											</xsl:if>
										</xsl:if>
									</xsl:when>
									<xsl:otherwise>
										<xsl:attribute name="value">
											<xsl:value-of select="@fixed"/>
										</xsl:attribute>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
							
							<xsl:if test="@default">
								<xsl:choose>
									<xsl:when test="$type = 'xs:boolean'">
										<xsl:if test="@default = 'true'">
											<xsl:if test="not(dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'[',$index,']')) = 'false')">
												<xsl:attribute name="checked">checked</xsl:attribute>
											</xsl:if>
										</xsl:if>
									</xsl:when>
									<xsl:otherwise>
										<xsl:attribute name="value">
											<xsl:value-of select="@default"/>
										</xsl:attribute>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
							
							<xsl:if test="@use = 'required'">
								<xsl:attribute name="required">required</xsl:attribute>
							</xsl:if>
							
							<xsl:if test="@use = 'prohibited'">
								<xsl:attribute name="readonly">readonly</xsl:attribute>
							</xsl:if>
							
							<xsl:call-template name="set-type-specifics-recursively"/>
							
							<xsl:call-template name="set-type-defaults">
								<xsl:with-param name="type">
									<xsl:value-of select="$type"/>
								</xsl:with-param>
							</xsl:call-template>
							
							<xsl:if test="not($invisible = 'true')">
								<xsl:if test="not(dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'[',$index,']'))) = ''">
									<xsl:attribute name="data-xsd2form-filled">true</xsl:attribute>
									<xsl:choose>
										<xsl:when test="@type = 'xs:boolean'">
											<xsl:if test="dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'[',$index,']')) = 'true'">
												<xsl:attribute name="checked">
													<xsl:text>checked</xsl:text>
												</xsl:attribute>
											</xsl:if>
										</xsl:when>
										<xsl:otherwise>
											<xsl:attribute name="value">
												<xsl:value-of select="dyn:evaluate(concat('exsl:node-set($xml-doc)',$tree,'[',$index,']'))" />
											</xsl:attribute>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:if>
							</xsl:if>
						</xsl:element>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:element>
			
			<!-- add descending extensions -->
			<xsl:apply-templates select="*/*/xs:extension/*">
				<xsl:with-param name="tree" select="concat($tree,'[',$index,']')" />
			</xsl:apply-templates>
			
			<!-- add inherited extensions -->
			<xsl:call-template name="add-extensions-recursively">
				<xsl:with-param name="tree" select="concat($tree,'[',$index,']')" />
			</xsl:call-template>
			
			<xsl:call-template name="handle-simple-element">
				<xsl:with-param name="id" select="$id" />
				<xsl:with-param name="description" select="$description" />
				<xsl:with-param name="no-remove-button" select="$no-remove-button" />
				<xsl:with-param name="count" select="$count - 1" />
				<xsl:with-param name="index" select="$index + 1" />
				<xsl:with-param name="tree" select="$tree" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="xs:sequence">
		<xsl:param name="tree" />
		<xsl:apply-templates select="xs:element|xs:attribute|xs:group">
			<xsl:with-param name="tree" select="$tree" />
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="xs:all">
		<xsl:param name="tree" />
		<xsl:apply-templates select="xs:element|xs:attribute|xs:group">
			<xsl:with-param name="tree" select="$tree" />
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="xs:choice">
		<xsl:param name="tree" />
		<xsl:apply-templates select="xs:element|xs:attribute|xs:group">
			<xsl:with-param name="choice" select="generate-id()" />
			<xsl:with-param name="tree" select="$tree" />
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- Recursively searches for xs:enumeration elements and applies templates on them -->
	<xsl:template name="handle-enumerations">
		<xsl:param name="default" />
		
		<xsl:variable name="type">
			<xsl:call-template name="get-type"/>
		</xsl:variable>
		
		<xsl:apply-templates select=".//xs:restriction/xs:enumeration" mode="input">
			<xsl:with-param name="default" select="$default" />
		</xsl:apply-templates>
		
		<xsl:for-each select="//xs:simpleType[@name=$type]">
			<xsl:call-template name="handle-enumerations">
				<xsl:with-param name="default" select="$default" />
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	
	<!-- Returns an element's description from xs:annotation/xs:documentation if it exists, or @name otherwise -->
	<xsl:template name="get-description">
		<xsl:choose>
			<xsl:when test="xs:annotation/xs:documentation">
				<xsl:value-of select="xs:annotation/xs:documentation/text()" />	
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@name" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Returns the first value that matches attr name -->
	<xsl:template name="attr-value">
		<xsl:param name="attr"/>
		
		<xsl:variable name="type">
			<xsl:call-template name="get-type"/>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="@*[contains(.,$attr)]">
				<xsl:value-of select="@*[contains(name(),$attr)]"/>
			</xsl:when>
			<xsl:when test=".//xs:restriction/*[contains(name(),$attr)]">
				<xsl:value-of select=".//xs:restriction/*[contains(name(),$attr)]/@value"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="//xs:simpleType[@name=$type]">
					<xsl:call-template name="attr-value">
						<xsl:with-param name="attr" select="$attr"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Returns the type directly specified by the calling node -->
	<xsl:template name="get-type">
		<xsl:choose>
			<xsl:when test="@type">
				<xsl:value-of select="@type"/>
			</xsl:when>
			<xsl:when test="xs:simpleType/xs:restriction/@base">
				<xsl:value-of select="xs:simpleType/xs:restriction/@base"/>
			</xsl:when>
			<xsl:when test="xs:restriction/@base">
				<xsl:value-of select="xs:restriction/@base"/>
			</xsl:when>
			<xsl:when test="xs:complexType/xs:simpleContent/xs:restriction/@base">
				<xsl:value-of select="xs:complexType/xs:simpleContent/xs:restriction/@base"/>
			</xsl:when>
			<xsl:when test="xs:simpleContent/xs:restriction/@base">
				<xsl:value-of select="xs:simpleContent/xs:restriction/@base"/>
			</xsl:when>
			<xsl:when test="xs:complexType/xs:simpleContent/xs:extension/@base">
				<xsl:value-of select="xs:complexType/xs:simpleContent/xs:extension/@base"/>
			</xsl:when>
			<xsl:when test="xs:simpleContent/xs:extension/@base">
				<xsl:value-of select="xs:simpleContent/xs:extension/@base"/>
			</xsl:when>
			<xsl:when test="xs:complexType/xs:complexContent/xs:extension/@base">
				<xsl:value-of select="xs:complexType/xs:complexContent/xs:extension/@base"/>
			</xsl:when>
			<xsl:when test="xs:complexContent/xs:extension/@base">
				<xsl:value-of select="xs:complexContent/xs:extension/@base"/>
			</xsl:when>
			<xsl:when test="xs:simpleType/xs:union/@memberTypes">
				<xsl:value-of select="xs:simpleType/xs:union/@memberTypes"/>
			</xsl:when>
			<xsl:when test="xs:union/@memberTypes">
				<xsl:value-of select="xs:simpleType/xs:union/@memberTypes"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<!-- Returns the original xs:* type specified by the calling node -->
	<xsl:template name="get-xs-type">
		<xsl:variable name="type">
			<xsl:call-template name="get-type"/>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="not(starts-with($type, 'xs:'))">
				<xsl:for-each select="//xs:simpleType[@name=$type]|//xs:complexType[@name=$type]">
					<xsl:call-template name="get-xs-type" />
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$type"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Applies templates recursively, overwriting lower-level options -->
	<xsl:template name="set-type-specifics-recursively">
		<xsl:variable name="type">
			<xsl:call-template name="get-type"/>
		</xsl:variable>
		
		<xsl:if test="not(starts-with($type, 'xs:'))">
			<xsl:for-each select="//xs:simpleType[@name=$type]|//xs:complexType[@name=$type]">
				<xsl:call-template name="set-type-specifics-recursively" />
			</xsl:for-each>
		</xsl:if>
		
		<xsl:apply-templates select=".//xs:restriction/xs:minInclusive" mode="input"/>
		<xsl:apply-templates select=".//xs:restriction/xs:maxInclusive" mode="input"/>
		
		<xsl:apply-templates select=".//xs:restriction/xs:minExclusive" mode="input"/>
		<xsl:apply-templates select=".//xs:restriction/xs:maxExclusive" mode="input"/>
		
		<xsl:apply-templates select=".//xs:restriction/xs:pattern" mode="input"/>
		<xsl:apply-templates select=".//xs:restriction/xs:length" mode="input"/>
	</xsl:template>
	
	<!-- Adds elements and attributes in extension recursively -->
	<xsl:template name="add-extensions-recursively">
		<xsl:param name="tree" />
		
		<xsl:variable name="type">
			<xsl:call-template name="get-type"/>
		</xsl:variable>
		
		<xsl:if test="not(starts-with($type, 'xs:'))">
			<xsl:for-each select="//xs:simpleType[@name=$type]|//xs:complexType[@name=$type]">
				<xsl:apply-templates select=".//xs:element|.//xs:attribute">
					<xsl:with-param name="tree" select="$tree" />
				</xsl:apply-templates>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="add-remove-button">
		<xsl:if test="(@minOccurs or @maxOccurs) and not(@minOccurs = @maxOccurs)">
			<xsl:element name="button">
				<xsl:attribute name="type">button</xsl:attribute>
				<xsl:attribute name="class">remove</xsl:attribute>
				<xsl:attribute name="onclick">
					if ((this.parentNode.parentNode.parentNode.children.length - 2) == this.parentNode.parentNode.parentNode.lastElementChild.getAttribute("data-xsd2form-max"))
						this.parentNode.parentNode.parentNode.lastElementChild.removeAttribute("disabled");
					
					this.parentNode.parentNode.parentNode.removeChild(
						this.parentNode.parentNode
					);
				</xsl:attribute>
				<xsl:text>-</xsl:text>
			</xsl:element>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="add-add-button">
		<xsl:param name="description" />
		
		<xsl:if test="(@minOccurs or @maxOccurs) and not(@minOccurs = @maxOccurs)">
			<xsl:element name="button">
				<xsl:attribute name="type">button</xsl:attribute>
				<xsl:attribute name="class">add</xsl:attribute>
				<xsl:attribute name="data-xsd2form-max">
					<xsl:value-of select="@maxOccurs" />
				</xsl:attribute>
				<xsl:attribute name="onclick">
					var newNode = this.previousElementSibling.cloneNode(true);
					newNode.removeAttribute("style");
					this.parentNode.insertBefore(
						newNode, this.previousElementSibling
					);
					if ((this.parentNode.children.length - 2) == this.getAttribute("data-xsd2form-max"))
						this.setAttribute("disabled", "true");
				</xsl:attribute>
				+ <xsl:value-of select="$description" />
			</xsl:element>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="add-choice-button">
		<xsl:param name="name" />
		<xsl:param name="description" />
		
		<xsl:element name="label">
			<xsl:element name="span">
				<xsl:value-of select="$description" />
			</xsl:element>
			<xsl:element name="input">
				<xsl:attribute name="type">radio</xsl:attribute>
				<xsl:attribute name="name">
					<xsl:value-of select="$name"/>
				</xsl:attribute>
				<xsl:attribute name="onclick">for (var i=0; i&lt;document.querySelectorAll("[name='<xsl:value-of select="$name" />']").length; i++) { document.querySelectorAll("[name='<xsl:value-of select="$name" />']")[i].removeAttribute("checked"); } this.setAttribute("checked","checked");</xsl:attribute>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	
	<!-- sets default values for xs:* types, but does not override already specified values -->
	<xsl:template name="set-type-defaults">
		<xsl:param name="type"/>
		
		<xsl:variable name="fractionDigits">
			<xsl:call-template name="attr-value">
				<xsl:with-param name="attr">xs:fractionDigits</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="$type = 'xs:decimal'">
				<xsl:attribute name="step">
					<xsl:choose>
						<xsl:when test="$fractionDigits!='' and $fractionDigits!='0'">
							<xsl:value-of select="concat('0.',substring('00000000000000000000',1,$fractionDigits - 1),'1')" />
						</xsl:when>
						<xsl:otherwise>0.1</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix">[-]?</xsl:with-param>
					<xsl:with-param name="allow-dot">true</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:float'">
				<xsl:attribute name="step">
					<xsl:choose>
						<xsl:when test="$fractionDigits!='' and $fractionDigits!='0'">
							<xsl:value-of select="concat('0.',substring('00000000000000000000',1,$fractionDigits - 1),'1')" />
						</xsl:when>
						<xsl:otherwise>0.1</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix">[-]?</xsl:with-param>
					<xsl:with-param name="allow-dot">true</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:double'">
				<xsl:attribute name="step">
					<xsl:choose>
						<xsl:when test="$fractionDigits!='' and $fractionDigits!='0'">
							<xsl:value-of select="concat('0.',substring('00000000000000000000',1,$fractionDigits - 1),'1')" />
						</xsl:when>
						<xsl:otherwise>0.1</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix">[-]?</xsl:with-param>
					<xsl:with-param name="allow-dot">true</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:byte'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">-128</xsl:with-param>
					<xsl:with-param name="max-value">127</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix">[-]?</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:unsignedByte'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">0</xsl:with-param>
					<xsl:with-param name="max-value">255</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:short'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">-32768</xsl:with-param>
					<xsl:with-param name="max-value">32767</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix">[-]?</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:unsignedShort'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">0</xsl:with-param>
					<xsl:with-param name="max-value">65535</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:int'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">-2147483648</xsl:with-param>
					<xsl:with-param name="max-value">2147483647</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix">[-]?</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:nonPositiveInteger'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">-2147483648</xsl:with-param>
					<xsl:with-param name="max-value">0</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix">[-]?</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:nonNegativeInteger'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">0</xsl:with-param>
					<xsl:with-param name="max-value">2147483647</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:positiveInteger'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">1</xsl:with-param>
					<xsl:with-param name="max-value">2147483647</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:negativeInteger'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">-2147483648</xsl:with-param>
					<xsl:with-param name="max-value">-1</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix">[-]?</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:unsignedInt'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">0</xsl:with-param>
					<xsl:with-param name="max-value">4294967295</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:long'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">-9223372036854775808</xsl:with-param>
					<xsl:with-param name="max-value">9223372036854775807</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix">[-]?</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$type = 'xs:unsignedLong'">
				<xsl:call-template name="set-numeric-range">
					<xsl:with-param name="min-value">0</xsl:with-param>
					<xsl:with-param name="max-value">18446744073709551615</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="set-pattern">
					<xsl:with-param name="prefix" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="set-pattern" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- sets min and max attributes if they have not been specified explicitly -->
	<xsl:template name="set-numeric-range">
		<xsl:param name="min-value"/>
		<xsl:param name="max-value"/>
		
		<xsl:variable name="minInclusive">
			<xsl:call-template name="attr-value">
				<xsl:with-param name="attr">xs:minInclusive</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="minExclusive">
			<xsl:call-template name="attr-value">
				<xsl:with-param name="attr">xs:minExclusive</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:if test="$minInclusive = '' and $minExclusive = ''">
			<xsl:attribute name="min">
				<xsl:value-of select="$min-value"/>
			</xsl:attribute>
		</xsl:if>
		
		<xsl:variable name="maxInclusive">
			<xsl:call-template name="attr-value">
				<xsl:with-param name="attr">xs:maxInclusive</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="maxExclusive">
			<xsl:call-template name="attr-value">
				<xsl:with-param name="attr">xs:maxExclusive</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:if test="$maxInclusive = '' and $maxExclusive = ''">
			<xsl:attribute name="max">
				<xsl:value-of select="$max-value"/>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>
	
	<!-- sets pattern attribute if it has not been specified explicitly -->
	<!-- numeric types (depending on totalDigits and fractionDigits) get regex patterns allowing digits and not counting the - and . -->
	<!-- other types (depending on minLength, maxLength, and length) get simpler regex patterns allowing any characters -->
	<xsl:template name="set-pattern">
		<xsl:param name="prefix">.</xsl:param>
		<xsl:param name="allow-dot">false</xsl:param>
		
		<xsl:variable name="pattern">
			<xsl:call-template name="attr-value">
				<xsl:with-param name="attr">xs:pattern</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:if test="$pattern=''">
			<xsl:variable name="length">
				<xsl:call-template name="attr-value">
					<xsl:with-param name="attr">xs:length</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="minLength">
				<xsl:call-template name="attr-value">
					<xsl:with-param name="attr">xs:minLength</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="maxLength">
				<xsl:call-template name="attr-value">
					<xsl:with-param name="attr">xs:maxLength</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="totalDigits">
				<xsl:call-template name="attr-value">
					<xsl:with-param name="attr">xs:totalDigits</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="fractionDigits">
				<xsl:call-template name="attr-value">
					<xsl:with-param name="attr">xs:fractionDigits</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:attribute name="pattern">
				<xsl:choose>
					<xsl:when test="$totalDigits!='' and $fractionDigits!=''">
						<xsl:value-of select="concat($prefix,'(?!\d{',$totalDigits + 1,'})(?!.*\.\d{',$totalDigits + 1 - $fractionDigits,',})[\d.]{0,',$totalDigits + 1,'}')" />
					</xsl:when>
					<xsl:when test="$totalDigits!='' and $allow-dot='true'">
						<xsl:value-of select="concat($prefix,'(?!\d{',$totalDigits + 1,'})[\d.]{0,',$totalDigits + 1,'}')" />
					</xsl:when>
					<xsl:when test="$totalDigits!='' and $allow-dot='false'">
						<xsl:value-of select="concat($prefix,'(?!\d{',$totalDigits,'})[\d]{0,',$totalDigits,'}')" />
					</xsl:when>
					<xsl:when test="$fractionDigits!=''">
						<xsl:value-of select="concat($prefix,'\d*(?:[.][\d]{0,',$fractionDigits,'})?')" />
					</xsl:when>
					<xsl:when test="not($length='')">
						<xsl:value-of select="concat($prefix,'{',$length,'}')" />
					</xsl:when>
					<xsl:when test="$minLength=''">
						<xsl:value-of select="concat($prefix,'{0,',$maxLength,'}')" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat($prefix,'{',$minLength,',',$maxLength,'}')" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="xs:minInclusive" mode="input">
		<xsl:attribute name="min">
			<xsl:value-of select="@value"/>
		</xsl:attribute>
	</xsl:template> 
	
	<xsl:template match="xs:maxInclusive" mode="input">
		<xsl:attribute name="max">
			<xsl:value-of select="@value"/>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="xs:minExclusive" mode="input">
		<xsl:attribute name="min">
			<xsl:value-of select="@value + 1"/>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="xs:maxExclusive" mode="input">
		<xsl:attribute name="max">
			<xsl:value-of select="@value - 1"/>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="xs:enumeration" mode="input">
		<xsl:param name="default" />
		
		<xsl:element name="option">
			<xsl:if test="$default = @value">
				<xsl:attribute name="selected">selected</xsl:attribute>
			</xsl:if>
			
			<xsl:value-of select="@value"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="xs:pattern" mode="input">
		<xsl:attribute name="pattern">
			<xsl:value-of select="@value"/>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="xs:length|xs:maxLength" mode="input">
		<xsl:attribute name="maxlength">
			<xsl:value-of select="@value"/>
		</xsl:attribute>
	</xsl:template>
	
</xsl:stylesheet>