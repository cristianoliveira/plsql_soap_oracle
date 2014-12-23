SOAP Webservices with PL/SQL Oracle
=============

Here are some objects types for Oracle Database to help manipulate SOAP XML.
We need to create two news types objXML and objSOAP.

Using
=====

Execute objXML.typ after objSOAP.typ to create the types and use objSOAP to access the WebService.

´´

	SOAP := NEW ObjSoap('Test Product', 'TestProduct', 'SOAPENV');

	SOAP.invoke(v_url, v_service, xml_send);

´´

For more details see "example.sql" file.



