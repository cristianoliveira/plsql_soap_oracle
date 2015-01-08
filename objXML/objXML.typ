CREATE OR REPLACE TYPE "OBJXML"    AS OBJECT
(
/*---------------------------------------------------------------------------------------------------
DATA        : 08/10/2014
AUTOR        : Cristian Oliveira
DESCRIPTION : Object to manipulate xml.
---------------------------------------------------------------------------------------------------*/

-- Attributes
    xml_obj    XMLTYPE,
    sponto     CHAR(4),
    error      VARCHAR2(500),
    blerro     CHAR(1),
    query      VARCHAR2(32767),
    xml_length INTEGER,
    rowset_tag VARCHAR2(255),

-- Member functions and procedures
    FINAL MEMBER FUNCTION htmlEntitiesDecode(xml IN VARCHAR2) RETURN VARCHAR2,
    FINAL MEMBER FUNCTION htmlEntitiesEncode(xml IN VARCHAR2) RETURN VARCHAR2,

    MEMBER FUNCTION getLastQuery RETURN VARCHAR2 DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION getErrorMessage RETURN VARCHAR2 DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION hasError RETURN BOOLEAN
        PARALLEL_ENABLE DETERMINISTIC,

    MEMBER PROCEDURE setXML(SELF IN OUT ObjXML
                                                    ,xml  IN XMLTYPE) DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION setXML(SELF IN OUT ObjXML
                                                ,xml  IN XMLTYPE) RETURN XMLTYPE DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION setXML(SELF IN OUT ObjXML
                                               ,xml  IN VARCHAR2) RETURN XMLTYPE DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION getXML RETURN XMLTYPE DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION getNodeValue(SELF IN OUT ObjXML
                                                         ,tag  VARCHAR2) RETURN XMLTYPE DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION getNode(SELF IN OUT ObjXML
                                                 ,tag  VARCHAR2) RETURN XMLTYPE DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION nodeExists(SELF IN OUT ObjXML
                                                     ,tag  VARCHAR2) RETURN BOOLEAN DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION append(SELF  IN OUT ObjXML
                                               ,tag   VARCHAR2
                                               ,o_xml ObjXML) RETURN XMLTYPE DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION remove(SELF IN OUT ObjXML
                                               ,tag  VARCHAR2) RETURN XMLTYPE DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION getXmlLength(SELF IN OUT ObjXML) RETURN INTEGER DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER PROCEDURE defineRowSetTag(SELF IN OUT ObjXML
                                                                  ,tag  VARCHAR2) DETERMINISTIC
        PARALLEL_ENABLE,

    MEMBER FUNCTION executeQuery(SELF IN OUT ObjXML) RETURN BOOLEAN DETERMINISTIC
        PARALLEL_ENABLE,

    CONSTRUCTOR FUNCTION ObjXML(squery VARCHAR2) RETURN SELF AS RESULT
        PARALLEL_ENABLE
)
NOT FINAL
/
CREATE OR REPLACE TYPE BODY "OBJXML" IS

    CONSTRUCTOR FUNCTION ObjXML(squery VARCHAR2) RETURN SELF AS RESULT AS
    BEGIN

        SELF.query := squery;
        defineRowSetTag('ROOT');

        IF (NOT SELF.executeQuery) THEN
            SELF.blerro := '1';
        END IF;

        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            SELF.error := SUBSTR(SQLCODE || '#ObjXM::CONSTRUCTOR' || sponto || ' - ' || SQLERRM, 1, 255);
            blerro     := '1';
            RETURN;
    END;

    FINAL MEMBER FUNCTION htmlEntitiesDecode(xml IN VARCHAR2) RETURN VARCHAR2 IS
        xml_tmp VARCHAR2(32767);
    BEGIN
        xml_tmp := xml;

        xml_tmp := REPLACE(xml_tmp, '&quot;', '"');
        xml_tmp := REPLACE(xml_tmp, '&apos;', '''');
        xml_tmp := REPLACE(xml_tmp, '&amp;', '&');
        xml_tmp := REPLACE(xml_tmp, '&lt;', '<');
        xml_tmp := REPLACE(xml_tmp, '&gt;', '>');

        RETURN xml_tmp;
    END;

    FINAL MEMBER FUNCTION htmlEntitiesEncode(xml IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN HTF.ESCAPE_SC(xml);
    END;

    MEMBER FUNCTION getLastQuery RETURN VARCHAR2 IS
    BEGIN
        RETURN SELF.query;
    END;

    MEMBER FUNCTION getErrorMessage RETURN VARCHAR2 IS
    BEGIN
        RETURN SELF.error;
    END;

    MEMBER FUNCTION hasError RETURN BOOLEAN IS
    BEGIN
        IF (SELF.blerro = '1') THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END;

    MEMBER PROCEDURE setXML(SELF IN OUT ObjXML
                                                    ,xml  IN XMLTYPE) IS
    BEGIN
        SELF.xml_obj := xml;

    EXCEPTION
        WHEN OTHERS THEN
            SELF.error := SUBSTR(SQLCODE || '#ObjXM::setXML' || sponto || ' - ' || SQLERRM, 1, 255);
            blerro     := '1';
    END;

    MEMBER FUNCTION setXML(SELF IN OUT ObjXML
                                                ,xml  IN XMLTYPE) RETURN XMLTYPE IS
    BEGIN
        SELF.xml_obj := xml;

        RETURN SELF.xml_obj;
    EXCEPTION
        WHEN OTHERS THEN
            SELF.error := SUBSTR(SQLCODE || '#ObjXM::setXML' || sponto || ' - ' || SQLERRM, 1, 255);
            blerro     := '1';
            RETURN SELF.xml_obj;
    END;

    MEMBER FUNCTION setXML(SELF IN OUT ObjXML
                                                ,xml  IN VARCHAR2) RETURN XMLTYPE IS
    BEGIN
        SELF.xml_obj := XMLTYPE.createxml(xml);

        RETURN SELF.xml_obj;
    EXCEPTION
        WHEN OTHERS THEN
            SELF.error := SUBSTR(SQLCODE || '#ObjXM::setXML' || sponto || ' - ' || SQLERRM, 1, 255);
            blerro     := '1';
            RETURN SELF.xml_obj;
    END;

    MEMBER FUNCTION getXML RETURN XMLTYPE IS
    BEGIN
        RETURN SELF.xml_obj;
    END;

    MEMBER FUNCTION getXmlLength(SELF IN OUT ObjXML) RETURN INTEGER IS
    BEGIN
        SELF.xml_length := LENGTH(SELF.xml_obj.getClobVal);
        RETURN SELF.xml_length;
    END;

    MEMBER FUNCTION getNodeValue(SELF IN OUT ObjXML
                                ,tag  VARCHAR2) RETURN XMLTYPE AS
    BEGIN
        RETURN SELF.xml_obj.extract('//' || tag || '/child::text()');

    EXCEPTION
        WHEN OTHERS THEN
            SELF.error := SUBSTR(SQLCODE || '#ObjXM::getNodeValue' || sponto || ' - ' || SQLERRM, 1, 255);
            blerro     := '1';
            RETURN SELF.xml_obj;

    END;

    MEMBER FUNCTION getNode(SELF IN OUT ObjXML
                           ,tag  VARCHAR2) RETURN XMLTYPE AS
    BEGIN
        RETURN SELF.xml_obj.extract('//' || tag);
    EXCEPTION
        WHEN OTHERS THEN
            SELF.error := SUBSTR(SQLCODE || '#ObjXM::getNode' || sponto || ' - ' || SQLERRM, 1, 255);
            blerro     := '1';
            RETURN SELF.xml_obj;
    END;

    MEMBER FUNCTION nodeExists(SELF IN OUT ObjXML
                              ,tag  VARCHAR2) RETURN BOOLEAN AS
    BEGIN
        IF (SELF.xml_obj.existsNode('//' || tag) > 0) THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            SELF.error := SUBSTR(SQLCODE || '#ObjXM::nodeExists' || sponto || ' - ' || SQLERRM, 1, 255);
            blerro     := '1';
            RETURN FALSE;
    END;

    MEMBER FUNCTION append(SELF  IN OUT ObjXML
                          ,tag   VARCHAR2
                          ,o_xml ObjXML) RETURN XMLTYPE AS
        tmp_xml XMLTYPE;
    BEGIN
        tmp_xml := SELF.xml_obj.appendChildXML('//' || tag, o_xml.getXML);
        setXML(tmp_xml);

        RETURN getXML();
    EXCEPTION
        WHEN OTHERS THEN
            SELF.error := SUBSTR(SQLCODE || '#ObjXM::append' || sponto || ' - ' || SQLERRM, 1, 255);
            blerro     := '1';
            RETURN SELF.xml_obj;
    END;

    MEMBER FUNCTION remove(SELF IN OUT ObjXML
                                               ,tag  VARCHAR2) RETURN XMLTYPE AS
        tmp_xml XMLTYPE;
    BEGIN
        tmp_xml := SELF.xml_obj.deleteXML('//' || tag);
        setXML(tmp_xml);

        RETURN tmp_xml;
    EXCEPTION
        WHEN OTHERS THEN
            SELF.error := SUBSTR(SQLCODE || '#ObjXM::remove' || sponto || ' - ' || SQLERRM, 1, 255);
            blerro     := '1';
            RETURN SELF.xml_obj;
    END;

    MEMBER PROCEDURE defineRowSetTag(SELF IN OUT ObjXML
                                                                   ,tag  VARCHAR2) AS
    BEGIN
        SELF.rowset_tag := tag;
    END;

    MEMBER FUNCTION executeQuery(SELF IN OUT ObjXML) RETURN BOOLEAN IS
        xml_aux  DBMS_XMLGEN.ctxHandle;
        clob_aux VARCHAR2(32767);
    BEGIN
        SELF.sponto := '#001';

        xml_aux     := DBMS_XMLGEN.newContext(query);
        SELF.sponto := '#002';

        dbms_xmlgen.setrowsettag(xml_aux, SELF.rowset_tag);
        SELF.sponto := '#003';
        dbms_xmlgen.setrowtag(xml_aux, NULL);
        SELF.sponto := '#004';

        clob_aux := DBMS_XMLGEN.getXML(xml_aux);

        SELF.sponto := '#005';

        -- Input root element
        clob_aux := TRIM(REGEXP_REPLACE(clob_aux, '\<\?xml version\=\"[0-9].[0-9]\"\?\>\D', ''));
        clob_aux := TRIM(REGEXP_REPLACE(clob_aux, '(\<.*S_ROW\>\D?\ ?)', ''));
        clob_aux := TRIM(REGEXP_REPLACE(clob_aux, '(\<[\/]?ROOT\>\D?)', ''));

        SELF.sponto := '#006';

        SELF.setXML(XMLTYPE.createxml(TRIM(clob_aux)));

        --DBMS_OUTPUT.put_line(getXML().getRootElement);
        --SELF.setXML(SELF.getNodeValue('//ROOT'));

        SELF.sponto := '#008';

        -- Close context
        DBMS_XMLGEN.closeContext(xml_aux);

        SELF.sponto := '#009';
        RETURN(TRUE);

    EXCEPTION
        WHEN OTHERS THEN
            SELF.error := SUBSTR(SQLCODE || '#ObjXM::executeQuery' || sponto || ' - ' || SQLERRM, 1, 255);
            blerro     := '1';
            RETURN(FALSE);

    END;

END;
/
