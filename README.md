# MongoDB Driver for Prolog

## Usage

Not much here for now, but clone the repository and run `make` to compile
the necessary C libraries and run the test suite. Part of the test suite
requires a MongoDB instance running on localhost on the default port.
See the tests (*.plt) in the src folder for usage examples.

## Example Usage

    ```prolog
    :- use_module(mongo(mongo)).

    todo :-
        format('--- Simple Todo ---~n'),
        mongo:new_connection(Connection),
        mongo:get_database(Connection, todo, Database),
        mongo:get_collection(Database, items, Collection),
        action(list, Collection),
        mongo:free_connection(Connection).

    action(list, Collection) :- !,
        list_items(Collection),
        new_action(Collection).
    action(add, Collection) :- !,
        add_item(Collection),
        new_action(Collection).
    action(delete, Collection) :- !,
        delete_item(Collection),
        new_action(Collection).
    action(quit, _Collection) :- !,
        format('Bye!~n').
    action(_Unknown, Collection) :-
        format('Unknown alternative.~n'),
        new_action(Collection).

    new_action(Collection) :-
        format('~nEnter list/add/delete/quit: '),
        read(Action),
        action(Action, Collection).

    list_items(Collection) :-
        mongo:find_all(Collection, [], [], Docs),
        print_items(Docs).

    print_items(Docs) :-
        format('Id~26|Label~45|Priority~n'),
        print_items_aux(Docs).

    print_items_aux([]).
    print_items_aux([Doc|Docs]) :-
        bson:doc_get(Doc, '_id', object_id(Id)),
        bson:doc_get(Doc, label, Label),
        bson:doc_get(Doc, priority, Priority),
        format('~w~26|~w~45|~w~n', [Id,Label,Priority]),
        print_items_aux(Docs).

    add_item(Collection) :-
        format('Label: '),
        read(Label),
        format('Priority: '),
        read(Priority),
        Doc = [label-Label,priority-Priority],
        mongo:insert(Collection, Doc).

    delete_item(Collection) :-
        format('Id: '),
        read(Id),
        mongo:delete(Collection, ['_id'-object_id(Id)]).
    ```

## Dependencies

 * SWI-Prolog (tested on Mac OS X using SWI 5.10.2)
    * Autoloading must be turned on (default).
 * ANSI C compiler (modify the Makefile if other than GCC)
 * MongoDB (tested on Mac OS X using MongoDB 1.8.x)

## Coding Guidelines

 * Use empty imports (use_module(mymodule, [])) in order to not
   pollute the namespace.
 * Always use module prefixes (mymodule:predicate(...)) in order to
   clarify where things are coming from.
 * Always use the "made-up" module prefix "core:" when calling
   built-in predicates. This is completely unnecessary, and maybe
   a bit weird, but I think it is a good idea as long as it doesn't
   cause any problems. This decision may need to be revised when
   compatibility between different Prologs is investigated.
 * Avoid the if-then-else construct. It just looks ugly.
 * Avoid disjunctions. They are ugly, and can be replaced by properly
   written helpers. Think: premises are "and", clauses are "or".
 * Use cuts where appropriate, and try to keep each cut on a line by
   itself unless its placement is obvious and consistent in each clause.
   PlUnit is excellent at pointing out when tests succeed but leave
   choice points.
 * Try to avoid spaces within lists and structures, but always use
   spaces between arguments.
 * Predicates, atoms, etc. should use "this_naming_style" while variables
   should use "ThisNamingStyle".
 * Try to stick to the PlDoc structure.
 * If in doubt, consult: <http://www.ai.uga.edu/mc/plcoding.pdf>

## Future

 * Refactor mongo tests. They are too complex.
 * Implement ordered documents? Omit for now.
 * Generate ObjectID's in the driver? Push to server for now.
 * Move BSON to separate repository (BSON is not inherent to MongoDB).
 * Test and improve compatibility between Prologs.
 * Make sure exception handling is more idiomatic.
 * (Implement all the stuff I won't have time to.)
