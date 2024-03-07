IMPORT os
IMPORT util

CONSTANT C_MAX_SHORTCUTS = 15

TYPE appmenu_t RECORD
        progid  VARCHAR(10),
        ndtype  CHAR(1), -- N=Node, P=Program
        ptitle  VARCHAR(40),
        parnod  VARCHAR(10),
        ndposi  SMALLINT,
        cmdexe  VARCHAR(100)
     END RECORD

DEFINE tree_arr DYNAMIC ARRAY OF RECORD
          progid_title STRING,
          parnod STRING,
          progid STRING,
          ndicon STRING,
          description STRING,
          ptitle STRING,
          ndtype CHAR(1),
          cmdexe STRING
       END RECORD

DEFINE params RECORD
           user_login STRING,
           comp_logo STRING,
           root_node STRING,
           ptitle_parent STRING,
           info_1 STRING,
           info_2 STRING,
           curr_date DATE,
           prog_code STRING,
           exec_name STRING
       END RECORD

DEFINE config RECORD
           shortcuts DYNAMIC ARRAY OF RECORD
               prog_code STRING
           END RECORD
       END RECORD

PRIVATE FUNCTION fetch_tree(p_parent VARCHAR(50)) RETURNS ()
    DEFINE a DYNAMIC ARRAY OF appmenu_t
    DEFINE t appmenu_t
    DEFINE i, j, n INT

    DECLARE cu1 CURSOR FOR
        SELECT * FROM appmenu_tree
         WHERE parnod = p_parent
          ORDER BY ndposi

    LET n = 0
    FOREACH cu1 INTO t.*
        LET n = n + 1
        LET a[n].* = t.*
    END FOREACH

    FOR i = 1 TO n
        LET j = tree_arr.getLength() + 1
        LET tree_arr[j].progid_title = SFMT("%1 - %2",
                                            a[i].progid CLIPPED,
                                            a[i].ptitle CLIPPED)
        LET tree_arr[j].progid = a[i].progid CLIPPED
        LET tree_arr[j].parnod = a[i].parnod CLIPPED
        LET tree_arr[j].ndicon = typmen_image(a[i].ndtype)
        LET tree_arr[j].description = util.JSON.stringify(a[i])
        LET tree_arr[j].ndtype = a[i].ndtype
        LET tree_arr[j].ptitle = a[i].ptitle CLIPPED
        LET tree_arr[j].cmdexe = a[i].cmdexe CLIPPED
        CALL fetch_tree(a[i].progid)
    END FOR

END FUNCTION

PUBLIC FUNCTION appmenu_init() RETURNS ()
    CALL add_presentation_styles()
END FUNCTION

PUBLIC FUNCTION appmenu_fini() RETURNS ()
END FUNCTION

PUBLIC FUNCTION appmenu_exec(
    login STRING,
    logo STRING,
    root_node STRING,
    curr_node STRING,
    info_1 STRING,
    info_2 STRING
) RETURNS STRING
    DEFINE tmp STRING

    LET tmp = SFMT("APPMENU - %1", root_node)
    OPEN WINDOW w_appmenu WITH FORM "appmenu" ATTRIBUTES(TEXT=tmp)

    IF root_node != NVL(params.root_node,"???") THEN
       DISPLAY "Loading program tree..." TO info_1
       CALL ui.Interface.refresh()
       CALL tree_arr.clear()
       CALL fetch_tree(root_node)
    END IF

    LET params.user_login = login
    LET params.comp_logo = logo
    LET params.root_node = root_node
    LET params.curr_date = TODAY
    LET params.info_1 = info_1
    LET params.info_2 = info_2

    CALL load_config()

    DIALOG ATTRIBUTES(UNBUFFERED)

        DISPLAY ARRAY tree_arr TO sr.* ATTRIBUTES(DOUBLECLICK=select)
           BEFORE ROW
              LET params.prog_code = tree_arr[arr_curr()].progid
              LET params.exec_name =  tree_arr[arr_curr()].cmdexe
              LET params.ptitle_parent = get_title(tree_arr[arr_curr()].parnod)
              CALL setup_dialog(DIALOG)
           ON ACTION select
              CALL setup_shortcuts(DIALOG, params.prog_code)
              IF tree_arr[arr_curr()].ndtype=="P" THEN
                 EXIT DIALOG
              END IF
        END DISPLAY

        INPUT BY NAME params.* ATTRIBUTES(WITHOUT DEFAULTS)
           BEFORE FIELD prog_code
              CALL setup_dialog(DIALOG)
           ON CHANGE prog_code
              CALL complete_code_prog(DIALOG, params.prog_code)
              CALL jump_to(DIALOG,params.prog_code)
              CALL setup_dialog(DIALOG)
        END INPUT

        BEFORE DIALOG
           IF curr_node IS NOT NULL THEN
              LET params.prog_code = curr_node
              CALL jump_to(DIALOG,params.prog_code)
           END IF
           CALL setup_dialog(DIALOG)

        ON ACTION accept
           CALL setup_dialog(DIALOG)
           EXIT DIALOG

        ON ACTION si_add ATTRIBUTES(ACCELERATOR="CONTROL-A")
           CALL add_shortcut(params.prog_code)
           CALL setup_shortcuts(DIALOG, params.prog_code)
        ON ACTION si_del ATTRIBUTES(ACCELERATOR="CONTROL-D")
           CALL del_shortcut("<FIRST>")
           CALL setup_shortcuts(DIALOG, params.prog_code)
        ON ACTION si_mvu ATTRIBUTES(ACCELERATOR="CONTROL-UP")
           CALL mvt_shortcut(params.prog_code,"U")
           CALL setup_shortcuts(DIALOG, params.prog_code)
        ON ACTION si_mvd ATTRIBUTES(ACCELERATOR="CONTROL-DOWN")
           CALL mvt_shortcut(params.prog_code,"D")
           CALL setup_shortcuts(DIALOG, params.prog_code)

&define ON_ACTION_START(nn) \
        ON ACTION start##nn \
           CALL start_shortcut(DIALOG,nn) \
                RETURNING tmp, params.prog_code \
           IF tmp=="P" THEN EXIT DIALOG END IF

        ON_ACTION_START(01)
        ON_ACTION_START(02)
        ON_ACTION_START(03)
        ON_ACTION_START(04)
        ON_ACTION_START(05)
        ON_ACTION_START(06)
        ON_ACTION_START(07)
        ON_ACTION_START(08)
        ON_ACTION_START(09)
        ON_ACTION_START(10)
        ON_ACTION_START(11)
        ON_ACTION_START(12)
        ON_ACTION_START(13)
        ON_ACTION_START(14)
        ON_ACTION_START(15)

        ON ACTION close
           LET params.prog_code = NULL
           EXIT DIALOG

    END DIALOG

    CALL save_config()

    CLOSE WINDOW w_appmenu

    RETURN params.prog_code

END FUNCTION

PRIVATE FUNCTION tree_arr_lookup(progid STRING) RETURNS INTEGER
    DEFINE x INTEGER
    FOR x=1 TO tree_arr.getLength()
        IF tree_arr[x].progid=progid THEN
           RETURN x
        END IF
    END FOR
    RETURN 0
END FUNCTION

PRIVATE FUNCTION jump_to(d ui.Dialog, cp VARCHAR(50)) RETURNS ()
    DEFINE x INTEGER
    LET x = tree_arr_lookup(cp)
    IF x > 0 THEN
       CALL d.setCurrentRow("sr",x)
    END IF
END FUNCTION

PRIVATE FUNCTION complete_code_prog(d ui.Dialog, val VARCHAR(50)) RETURNS ()
    DEFINE codes DYNAMIC ARRAY OF STRING
    DEFINE x, i SMALLINT
    IF length(val)<=1 THEN
       CALL d.setCompleterItems(codes)
       RETURN
    END IF
    LET val = val, "*"
    LET i=0
    FOR x=1 TO tree_arr.getLength()
        IF tree_arr[x].ndtype=="P" AND tree_arr[x].progid MATCHES val THEN
           LET i=i+1
           LET codes[i] = tree_arr[x].progid CLIPPED
           IF i>=50 THEN EXIT FOR END IF
        END IF
    END FOR
    CALL d.setCompleterItems(codes)
END FUNCTION

PRIVATE FUNCTION setup_dialog(d ui.Dialog) RETURNS ()
    DEFINE x INTEGER,
           can_exec BOOLEAN
    IF d.getCurrentItem()=="prog_code" THEN
       -- FIXME: Missing trigger when returning from completer selection,
       --        but ON CHANGE is already used...
       -- LET x = tree_arr_lookup(params.prog_code)
       -- IF x>0 THEN
       --    LET can_exec = ( tree_arr[x].ndtype == "P" )
       -- END IF
       LET can_exec = (length(params.prog_code)>2)
    ELSE
       LET x = d.getCurrentRow("sr")
       IF x>0 THEN
          LET can_exec = ( tree_arr[x].ndtype == "P" )
       END IF
    END IF
    CALL d.setActionActive("accept",can_exec)
    CALL setup_shortcuts(d, params.prog_code)
END FUNCTION

PRIVATE FUNCTION start_shortcut(d ui.Dialog, x SMALLINT) RETURNS (STRING,STRING)
    DEFINE i SMALLINT,
           cp STRING
    IF x>=1 AND x<=config.shortcuts.getLength() THEN
       LET cp = config.shortcuts[x].prog_code
       LET i = tree_arr_lookup(cp)
       IF i>0 THEN
          LET params.prog_code = cp
          CALL jump_to(d,cp)
          RETURN tree_arr[i].ndtype, cp
       END IF
       CALL setup_dialog(d)
    END IF
    RETURN "?", NULL
END FUNCTION

PRIVATE FUNCTION config_filename() RETURNS STRING
    IF length(params.user_login)==0
    OR length(params.root_node)==0
    THEN
       ERROR "Cannot build configuration file name"
       RETURN NULL
    END IF
    RETURN SFMT("%1/appmenu_%2_%3.conf",
                fgl_getenv("HOME"),
                params.user_login CLIPPED,
                params.root_node
               )
END FUNCTION

PRIVATE FUNCTION load_config() RETURNS ()
    DEFINE cs STRING,
           fn STRING,
           ch base.Channel
    LET fn = config_filename()
    IF fn IS NULL THEN RETURN END IF
    IF NOT os.Path.exists(fn) THEN RETURN END IF
    TRY
        LET ch = base.Channel.create()
        CALL ch.openFile(fn,"r")
        LET cs = ch.readLine()
        CALL ch.close()
        IF cs IS NOT NULL THEN
           CALL util.JSON.parse(cs, config)
        END IF
    CATCH
        ERROR SFMT("Cannot load configuration file [%1]", fn)
    END TRY
END FUNCTION

PRIVATE FUNCTION save_config() RETURNS ()
    DEFINE cs STRING,
           fn STRING,
           ch base.Channel
    LET fn = config_filename()
    IF fn IS NULL THEN RETURN END IF
    TRY
        LET ch = base.Channel.create()
        CALL ch.openFile(fn,"w")
        LET cs = util.JSON.stringify(config)
        CALL ch.writeLine(cs)
        CALL ch.close()
    CATCH
        ERROR SFMT("Cannot save configuration file [%1]", fn)
    END TRY
END FUNCTION

PRIVATE FUNCTION set_element_attribute(
    f ui.Form,
    t STRING,
    n STRING,
    a STRING,
    v STRING
) RETURNS ()
    DEFINE root, node om.DomNode,
           nl om.NodeList
    LET root = f.getNode()
    LET nl = root.selectByPath(SFMT("//%1[@name=\"%2\"]",t,n))
    IF nl.getLength()==1 THEN
       LET node = nl.item(1)
       CALL node.setAttribute(a, v)
    END IF
END FUNCTION

PRIVATE FUNCTION setup_shortcuts(d ui.Dialog, cp STRING) RETURNS ()
    DEFINE x SMALLINT,
           f ui.Form,
           an, lcp, cmt STRING,
           i SMALLINT
    LET x = lookup_shortcut(cp)
    CALL d.setActionActive("si_add", (x==0 AND config.shortcuts.getLength()<C_MAX_SHORTCUTS) )
    CALL d.setActionActive("si_del", (config.shortcuts.getLength()>0) )
    CALL d.setActionActive("si_mvu", (x>1) )
    CALL d.setActionActive("si_mvd", (x>0 AND x<config.shortcuts.getLength()) )
    LET f = d.getForm()
    FOR x=1 TO C_MAX_SHORTCUTS
        LET an = SFMT("start%1",(x USING "&&"))
        CALL d.setActionActive(an, FALSE)
        CALL f.setElementHidden(an, 1)
        CALL set_element_attribute(f, "Button", an, "comment", NULL)
        IF x<=config.shortcuts.getLength() THEN
           LET lcp = config.shortcuts[x].prog_code
           LET i = tree_arr_lookup(lcp)
           IF i > 0 THEN
              IF lcp = cp THEN
                 LET lcp=SFMT("[ %1 ]",cp)
              END IF
              CALL f.setElementText(an, lcp)
              CALL d.setActionActive(an, TRUE)
              LET cmt = tree_arr[i].ptitle
           ELSE
              CALL f.setElementText(an, SFMT("(%1)",lcp))
              LET cmt = "This shortcut is not in the current tree"
           END IF
           CALL f.setElementHidden(an, 0)
           CALL set_element_attribute(f, "Button", an, "comment", cmt)
        END IF
    END FOR
    --CALL f.setElementHidden("g_shortcuts", (config.shortcuts.getLength()==0) )
END FUNCTION

PRIVATE FUNCTION lookup_shortcut(cp STRING) RETURNS INTEGER
    DEFINE x SMALLINT
    FOR x=1 TO config.shortcuts.getLength()
        IF config.shortcuts[x].prog_code == cp THEN
           RETURN x
        END IF
    END FOR
    RETURN 0
END FUNCTION

PRIVATE FUNCTION add_shortcut(cp STRING) RETURNS ()
    DEFINE x SMALLINT
    LET x = lookup_shortcut(cp) 
    IF x==0 THEN
       IF config.shortcuts.getLength()==C_MAX_SHORTCUTS THEN
          RETURN
       END IF
       CALL config.shortcuts.insertElement(1)
       LET config.shortcuts[1].prog_code = cp.trim()
    END IF
END FUNCTION

PRIVATE FUNCTION mvt_shortcut(cp STRING, dir CHAR(1)) RETURNS ()
    DEFINE x SMALLINT
    LET x = lookup_shortcut(cp) 
    IF x == 0 THEN RETURN END IF
    IF dir=="D" THEN
       IF x < config.shortcuts.getLength() THEN
          CALL config.shortcuts.insertElement(x)
          LET config.shortcuts[x].* = config.shortcuts[x+2].*
          CALL config.shortcuts.deleteElement(x+2)
       END IF
    ELSE
       IF x > 1 THEN
          CALL config.shortcuts.insertElement(x-1)
          LET config.shortcuts[x-1].* = config.shortcuts[x+1].*
          CALL config.shortcuts.deleteElement(x+1)
       END IF
    END IF
END FUNCTION

PRIVATE FUNCTION del_shortcut(cp STRING) RETURNS ()
    DEFINE x SMALLINT
    CASE cp
      WHEN "<FIRST>"
        CALL config.shortcuts.deleteElement( 1 )
      WHEN "<LAST>"
        CALL config.shortcuts.deleteElement( config.shortcuts.getLength() )
      OTHERWISE
        LET x = lookup_shortcut(cp) 
        IF x>0 THEN
           CALL config.shortcuts.deleteElement(x)
        END IF
    END CASE
END FUNCTION

PRIVATE FUNCTION typmen_image(ndtype STRING) RETURNS STRING
    CASE ndtype
        WHEN "P" RETURN "fa-cogs"
        WHEN "N" RETURN "fa-cube"
    END CASE
    RETURN NULL
END FUNCTION

PRIVATE FUNCTION get_title(parnod STRING) RETURNS VARCHAR(50)
    DEFINE x INTEGER,
           res VARCHAR(50)
    IF parnod==params.root_node THEN
       SELECT ptitle INTO res FROM appmenu_tree WHERE progid=params.root_node
    ELSE
       FOR x=1 TO tree_arr.getLength()
           IF tree_arr[x].progid=parnod THEN
              LET res = tree_arr[x].ptitle
              EXIT FOR
           END IF
       END FOR
    END IF
    RETURN res
END FUNCTION

PRIVATE FUNCTION get_aui_node(
    p om.DomNode,
    tagname STRING,
    aname STRING
) RETURNS om.DomNode
    DEFINE nl om.NodeList
    IF aname IS NOT NULL THEN
       LET nl = p.selectByPath(SFMT("//%1[@name=\"%2\"]",tagname,aname))
    ELSE
       LET nl = p.selectByPath(SFMT("//%1",tagname))
    END IF
    IF nl.getLength() == 1 THEN
       RETURN nl.item(1)
    ELSE
       RETURN NULL
    END IF
END FUNCTION

PRIVATE FUNCTION add_style(pn om.DomNode, aname STRING) RETURNS om.DomNode
    DEFINE nn om.DomNode
    LET nn = get_aui_node(pn, "Style", aname)
    IF nn IS NOT NULL THEN RETURN NULL END IF
    LET nn = pn.createChild("Style")
    CALL nn.setAttribute("name", aname)
    RETURN nn
END FUNCTION

PRIVATE FUNCTION set_style_attribute(pn om.DomNode, aname STRING, value STRING) RETURNS ()
    DEFINE sa om.DomNode
    LET sa = get_aui_node(pn, "StyleAttribute", aname)
    IF sa IS NULL THEN
       LET sa = pn.createChild("StyleAttribute")
       CALL sa.setAttribute("name", aname)
    END IF
    CALL sa.setAttribute("value", value)
END FUNCTION

PUBLIC FUNCTION add_presentation_styles() RETURNS ()
    DEFINE rn om.DomNode,
           sl om.DomNode,
           nn om.DomNode
    LET rn = ui.Interface.getRootNode()
    LET sl = get_aui_node(rn, "StyleList", NULL)
    --
    LET nn = add_style(sl, "Label.appmenu_title")
    IF nn IS NOT NULL THEN
       CALL set_style_attribute(nn, "fontSize", "large")
       CALL set_style_attribute(nn, "fontWeight", "bold")
       CALL set_style_attribute(nn, "textColor", "blue")
    END IF
    --
    LET nn = add_style(sl, "Label.appmenu_info")
    IF nn IS NOT NULL THEN
       CALL set_style_attribute(nn, "fontSize", "small")
       CALL set_style_attribute(nn, "fontStyle", "italic")
       CALL set_style_attribute(nn, "textColor", "gray")
    END IF
END FUNCTION
