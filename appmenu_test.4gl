IMPORT FGL libappmenu
MAIN
    DEFINE rec RECORD
               root_node STRING,
               curr_node STRING
           END RECORD
    DEFER INTERRUPT
    DEFER QUIT
    CALL appmenu_init()
    CONNECT TO ":memory:+driver='dbmsqt'"
    CALL create_tree()
    OPTIONS INPUT WRAP
    OPEN FORM f1 FROM "appmenu_test"
    DISPLAY FORM f1
    LET rec.root_node = "ROOT"
    INPUT BY NAME rec.* WITHOUT DEFAULTS
          ATTRIBUTES(UNBUFFERED, ACCEPT=FALSE)
       BEFORE INPUT
          NEXT FIELD curr_node
       ON ACTION start_menu ATTRIBUTES(TEXT="Menu")
          LET rec.curr_node = appmenu_exec("mike", "fourjs_logo.png",
                                           rec.root_node, rec.curr_node,
                                           "Info 1", "Info 2")
    END INPUT
    CALL appmenu_fini()
END MAIN

PRIVATE FUNCTION create_tree()

    CREATE TABLE appmenu_tree (
        progid  VARCHAR(10) NOT NULL PRIMARY KEY,
        ndtype  CHAR(1) NOT NULL,
        ptitle  VARCHAR(40) NOT NULL,
        parnod  VARCHAR(10),
        ndposi  SMALLINT NOT NULL,
        cmdexe  VARCHAR(100),
        UNIQUE (progid, parnod)
    )

    INSERT INTO appmenu_tree VALUES ( "ROOT", "N", "Root node", NULL, 1, NULL )

    INSERT INTO appmenu_tree VALUES ( "CF",  "N", "Configuration",      "ROOT", 1, NULL )
      INSERT INTO appmenu_tree VALUES ( "CFDBD",  "P", "Database server",  "CF", 1, "config_dbsrv" )
      INSERT INTO appmenu_tree VALUES ( "CFUSR",  "P", "User definition",  "CF", 2, "config_users" )
      INSERT INTO appmenu_tree VALUES ( "CFPER",  "P", "User permissions", "CF", 3, "condig_perms" )

    INSERT INTO appmenu_tree VALUES ( "ST",  "N", "Stock management",   "ROOT", 2, NULL )
      INSERT INTO appmenu_tree VALUES ( "STITM",  "P", "Items",       "ST", 1, "stock_items" )
      INSERT INTO appmenu_tree VALUES ( "STWAR",  "P", "Warehouses",  "ST", 2, "stock_warehouses" )
      INSERT INTO appmenu_tree VALUES ( "STT",    "N", "Transport",   "ST", 3, NULL )
        INSERT INTO appmenu_tree VALUES ( "STTDRV",    "P", "Drivers",   "STT", 1, "transport_drivers" )
        INSERT INTO appmenu_tree VALUES ( "STTTRN",    "P", "Trains",    "STT", 2, "transport_trains" )
        INSERT INTO appmenu_tree VALUES ( "STTTRK",    "P", "Trucks",    "STT", 3, "transport_trucks" )

END FUNCTION


