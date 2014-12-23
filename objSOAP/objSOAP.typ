CREATE OR REPLACE TYPE "OBJSOAP" UNDER ObjXML --AS OBJECT
(
/*---------------------------------------------------------------------------------------------------
DATA		: 08/10/2014
AUTOR		: Cristian Oliveira
DESCRIPTION : Object to manipulate xml from SOAP webserver.
---------------------------------------------------------------------------------------------------*/

-- Attributes
	method       VARCHAR2(256),
	namespace    VARCHAR2(256),
	tag_body     VARCHAR2(32767),
	envelope_tag VARCHAR2(30),
	doc          XMLTYPE,
	encoding     VARCHAR2(50),

	l_fault_code   VARCHAR2(256),
	l_fault_string XMLTYPE,

-- Member functions and procedures
	MEMBER PROCEDURE addParameter(SELF    IN OUT NOCOPY ObjSoap
								 ,p_name  IN VARCHAR2
								 ,p_value IN VARCHAR2
								 ,p_type  IN VARCHAR2 DEFAULT NULL)
		PARALLEL_ENABLE,

	MEMBER PROCEDURE invoke(SELF       IN OUT NOCOPY ObjSoap
						   ,p_url      IN VARCHAR2
						   ,p_action   IN VARCHAR2
						   ,l_envelope IN VARCHAR2 DEFAULT NULL)
		PARALLEL_ENABLE,

	MEMBER FUNCTION getReturnValue(SELF        IN OUT NOCOPY ObjSoap
								  ,p_name      IN VARCHAR2
								  ,p_namespace IN VARCHAR2) RETURN XMLTYPE
		PARALLEL_ENABLE,

	MEMBER PROCEDURE showEnvelope(p_env IN VARCHAR2)
		PARALLEL_ENABLE,

	MEMBER PROCEDURE generateEnvelope(SELF  IN OUT NOCOPY ObjSoap
									 ,p_env IN OUT NOCOPY VARCHAR2)
		PARALLEL_ENABLE,

	MEMBER PROCEDURE checkFault(SELF IN OUT NOCOPY ObjSoap)
		PARALLEL_ENABLE,

	MEMBER PROCEDURE setDocument(SELF IN OUT NOCOPY ObjSoap)
		PARALLEL_ENABLE,
	MEMBER FUNCTION getDocument(SELF IN OUT NOCOPY ObjSoap) RETURN XMLTYPE
		PARALLEL_ENABLE,

	MEMBER FUNCTION getXML(SELF IN OUT NOCOPY ObjSoap) RETURN XMLTYPE
		PARALLEL_ENABLE,

	MEMBER PROCEDURE setResponse(SELF        IN OUT NOCOPY ObjSoap
								,strResponse IN VARCHAR2),

	CONSTRUCTOR FUNCTION ObjSoap(method       IN VARCHAR2 DEFAULT ''
								,namespace    IN VARCHAR2 DEFAULT ''
								,envelope_tag IN VARCHAR2 DEFAULT 'SOAP-ENV'
								,p_encoding   IN VARCHAR2 DEFAULT 'WE8ISO8859P1') RETURN SELF AS RESULT

)
NOT FINAL
/
CREATE OR REPLACE TYPE BODY "OBJSOAP" IS

	CONSTRUCTOR FUNCTION ObjSoap(method       IN VARCHAR2 DEFAULT ''
								,namespace    IN VARCHAR2 DEFAULT ''
								,envelope_tag IN VARCHAR2 DEFAULT 'SOAP-ENV'
								,p_encoding   IN VARCHAR2 DEFAULT 'WE8ISO8859P1') RETURN SELF AS RESULT AS
	BEGIN
		SELF.method       := method;
		SELF.namespace    := namespace;
		SELF.envelope_tag := envelope_tag;
		SELF.encoding     := p_encoding;

		RETURN;

	EXCEPTION
		WHEN OTHERS THEN
			SELF.error := SUBSTR(SQLCODE || '#ObjSoap::CONSTRUCTOR' || sponto || ' - ' || SQLERRM, 1, 255);
			blerro     := '1';
			RETURN;
	END;

	MEMBER PROCEDURE addParameter(SELF    IN OUT NOCOPY ObjSoap
								 ,p_name  IN VARCHAR2
								 ,p_value IN VARCHAR2
								 ,p_type  IN VARCHAR2 DEFAULT NULL) AS
	BEGIN
		IF (p_type IS NOT NULL) THEN
			SELF.tag_body := SELF.tag_body || '<' || p_name || ' xsi:type="' || p_type || '">' || p_value || '</' ||
							 p_name || '>';
		ELSE
			SELF.tag_body := SELF.tag_body || '<' || p_name || '>' || p_value || '</' || p_name || '>';
		END IF;
	END;

	MEMBER PROCEDURE generateEnvelope(SELF  IN OUT NOCOPY ObjSoap
									 ,p_env IN OUT NOCOPY VARCHAR2) AS
		tmpXMLTYPE XMLTYPE;
	BEGIN

		p_env := '<' || LOWER(TRIM(SELF.envelope_tag)) || ':Envelope xmlns:' || LOWER(TRIM(SELF.envelope_tag)) ||
				 '="http://schemas.xmlsoap.org/soap/envelope/" ' || LOWER(TRIM(SELF.namespace)) || '><' ||
				 LOWER(TRIM(SELF.envelope_tag)) || ':Header/><' || LOWER(TRIM(SELF.envelope_tag)) || ':Body>' ||
				 TRIM(SELF.tag_body) || '</' || LOWER(TRIM(SELF.envelope_tag)) || ':Body></' ||
				 LOWER(TRIM(SELF.envelope_tag)) || ':Envelope>';

		tmpXMLTYPE := XMLTYPE(p_env);

		ObjXML.setXML(SELF, tmpXMLTYPE);

		p_env := ObjXML.getXML(SELF).getStringVal;
	EXCEPTION
		WHEN OTHERS THEN
			SELF.error := SUBSTR(SQLCODE || '#ObjSoap::generateEnvelope' || sponto || ' - ' || SQLERRM, 1, 255);
			blerro     := '1';
	END;

	MEMBER PROCEDURE showEnvelope(p_env IN VARCHAR2) AS
		i     PLS_INTEGER;
		l_len PLS_INTEGER;
	BEGIN
		i     := 1;
		l_len := LENGTH(p_env);
		WHILE (i <= l_len)
		LOOP
			DBMS_OUTPUT.put_line(SUBSTR(p_env, i, 60));
			i := i + 60;
		END LOOP;
	END;

	MEMBER PROCEDURE checkFault(SELF IN OUT NOCOPY ObjSoap) AS
		l_fault_node XMLTYPE;
	BEGIN
		l_fault_node := SELF.doc.extract('/' || SELF.envelope_tag || ':Fault',
										 'xmlns:' || SELF.envelope_tag || '="http://schemas.xmlsoap.org/soap/envelope/"');
		IF (l_fault_node IS NOT NULL) THEN
			SELF.l_fault_code   := SELF.doc.extract('/' || SELF.envelope_tag || ':Fault/faultcode/child::text()')
								  .getStringVal;
			SELF.l_fault_string := SELF.doc.extract('/' || SELF.envelope_tag || ':Fault/faultstring/child::text()');

			SELF.blerro := '1';
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			SELF.error := SUBSTR(SQLCODE || '#ObjSoap::checkFault' || sponto || ' - ' || SQLERRM, 1, 255);
			blerro     := '1';
	END;

	MEMBER PROCEDURE setDocument(SELF IN OUT NOCOPY ObjSoap) AS
	BEGIN
		SELF.doc := objXML.getXML(SELF)
				   .extract('/' || SELF.envelope_tag || ':Envelope/' || SELF.envelope_tag || ':Body/child::node()',
							'xmlns:' || SELF.envelope_tag || '="http://schemas.xmlsoap.org/soap/envelope/"');
	EXCEPTION
		WHEN OTHERS THEN
			SELF.error := SUBSTR(SQLCODE || '#ObjSoap::setDocument' || sponto || ' - ' || SQLERRM, 1, 255);
			blerro     := '1';
	END;

	MEMBER FUNCTION getDocument(SELF IN OUT ObjSoap) RETURN XMLTYPE AS
	BEGIN
		RETURN SELF.doc;
	END;

	MEMBER FUNCTION getXML(SELF IN OUT NOCOPY ObjSoap) RETURN XMLTYPE AS
	BEGIN
		RETURN ObjXML.getXML(SELF);
	END;

	MEMBER PROCEDURE setResponse(SELF        IN OUT ObjSoap
								,strResponse IN VARCHAR2) AS
		erro VARCHAR2(30000);
	BEGIN

		objXML.setXML(SELF, XMLTYPE.createxml(strResponse));
		setDocument();
	EXCEPTION
		WHEN OTHERS THEN
			SELF.error := SUBSTR(SQLCODE || '#ObjSoap::setResponse' || sponto || ' - ' || SQLERRM, 1, 255);
			erro       := SQLERRM;
			blerro     := '1';
	END;

	MEMBER FUNCTION getReturnValue(SELF        IN OUT NOCOPY ObjSoap
								  ,p_name      IN VARCHAR2
								  ,p_namespace IN VARCHAR2) RETURN XMLTYPE AS
	BEGIN
		RETURN SELF.doc.extract('//' || p_name || '/child::text()', p_namespace);
	EXCEPTION
		WHEN OTHERS THEN
			SELF.error := SUBSTR(SQLCODE || '#ObjSoap::getReturnValue' || sponto || ' - ' || SQLERRM, 1, 255);
			blerro     := '1';
	END;

	MEMBER PROCEDURE invoke(p_url      IN VARCHAR2
						   ,p_action   IN VARCHAR2
						   ,l_envelope IN VARCHAR2 DEFAULT NULL) AS

		l_envelope_tmp VARCHAR2(32767);
		http_request   UTL_HTTP.req;
		http_response  UTL_HTTP.resp;

	BEGIN
		l_envelope_tmp := NULL;

		IF (l_envelope IS NULL) THEN
			generateEnvelope(l_envelope_tmp);
		ELSE
			l_envelope_tmp := l_envelope;
		END IF;

		http_request := UTL_HTTP.begin_request(p_url, 'POST', 'HTTP/1.1');

		UTL_HTTP.set_header(http_request, 'Content-Type', 'text/xml');
		UTL_HTTP.set_header(http_request, 'Content-Length', LENGTH(l_envelope_tmp));
		UTL_HTTP.set_header(http_request, 'SOAPAction', p_action);
		UTL_HTTP.write_text(http_request, l_envelope_tmp);
		http_response := UTL_HTTP.get_response(http_request);
		UTL_HTTP.read_text(http_response, l_envelope_tmp);
		UTL_HTTP.end_response(http_response);

		setResponse(l_envelope_tmp);
	EXCEPTION
		WHEN OTHERS THEN
			SELF.error := SUBSTR(SQLCODE || '#ObjSoap::invoke' || sponto || ' - ' || SQLERRM, 1, 255);
			blerro     := '1';
	END;
END;
/
