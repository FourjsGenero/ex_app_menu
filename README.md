# Genero program launch menu  

## Description

This Genero BDL demo implements a general launch menu to start other programs.

The module implements a treeview to let the user browse in the program tree
and start a program.

Each program is identifier by a code and can be executed directly with the code.

In this version, when the user selects a program, the launcher closes itself
and returns the program code. The code can be easily modified if you want to
keep the launcher open after selecting a program to start.

![Genero program launcher (GDC)](https://github.com/FourjsGenero/ex_app_menu/raw/master/docs/appmenu-screen-001.png)

## Prerequisites

* Genero BDL 3.10+
* Genero Desktop Client 3.10+
* Genero Studio 3.10+
* GNU Make

## Compilation from command line

1. make clean all

## Compilation in Genero Studio

1. Load the appmenu.4pw project
2. Build the project

## Usage

1. Start the program
2. Browse the treeview
3. Select a leaf node to be executed
4. Append/Delete/Move shortcuts

## Programmer's reference

### Database structure

The main program must provide a database table containing the definition of
the program tree as set of nodes with parent/child references:

```SQL
    CREATE TABLE appmenu_tree (
        progid  VARCHAR(10) NOT NULL PRIMARY KEY,  -- Program id
        ndtype  CHAR(1) NOT NULL,                  -- N = Node, P = Program
        ptitle  VARCHAR(40) NOT NULL,              -- title to be displayed
        parnod  VARCHAR(10),                       -- link to parent node id
        ndposi  SMALLINT NOT NULL,                 -- position in parent node
        cmdexe  VARCHAR(100),                      -- command to execute 
        UNIQUE (progid, parnod)
    )
```

### APIs

* appmenu_init(): Module initialization function to be called before others.
* appmenu_fini(): Module finalization function to be called when lib is no longer needed.
* appmenu_exec(): Open the program launcher window, see code for details.

## Bug fixes:

