DECLARE

	SOAP ObjSoap;

	v_url     VARCHAR(1000) := 'www.mywebservice.com/soap/';
	v_service VARCHAR(1000) := 'testproduct';

	xml_send    VARCHAR2(32767) := '<?xml version="1.0" encoding="utf-8"?>
		 <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
		   <soap:Body>
			 <TestProduct xmlns="[ACTION]">
			   <CodProduct>[PRODUCT]</CodProduct>
			 </TestProduct>
		   </soap:Body>
		 </soap:Envelope>';
	
    xml_return VARCHAR2(32767);

	v_return   VARCHAR2(10000);
	v_stRetorn VARCHAR2(1000);

	v_xml XMLTYPE;

	ERROR_WEBSERRVICE EXCEPTION;

	PROCEDURE bind(sVar VARCHAR2
				  ,sVal VARCHAR2) IS
	BEGIN
		xml_send := REPLACE(xml_send, sVar, sVal);
	END;
BEGIN

	bind('[ACTION]', 'TestProduct');
	bind('[PRODUCT]', '001');

	SOAP := NEW ObjSoap('Test Product', 'TestProduct', 'SOAPENV');

	SOAP.invoke(v_url, v_service, xml_send);

	IF SOAP.error IS NOT NULL THEN
		dbms_output.put_line('ERROR webservice: ' || SOAP.error);
		RAISE ERROR_WEBSERRVICE;
	END IF;

	IF SOAP.nodeExists('TestProduct/Message') THEN
		v_return := SOAP.getNodeValue('TestProduct/Message').getStringVal();
		dbms_output.put_line('Message: ' || v_return);
		RETURN;
	END IF;

    --xml_return := SOAP.htmlEntitiesDecode(SOAP.getXML().getStringVal);
	--v_xml       := f_clean_xml(xml_retorno);
	--SOAP.Setxml(v_xml);

EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line('ERROR ' || SQLERRM);
	
END;
