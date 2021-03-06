/** <module> Command handling.
 */

:- module(_, [
    command/3,
    command/4,
    list_commands/2,
    list_collection_names/2,
    list_database_infos/2,
    list_database_names/2,
    drop_collection/1,
    drop_database/1,
    get_last_error/2
]).

:- include(include/common).

command_collection('$cmd').
admin_database('admin').

database_cmd_collection(Database, CmdColl) :-
    command_collection(CmdCollName),
    mongo_database:get_collection(Database, CmdCollName, CmdColl).

%%  command(+Database, +Query, -Doc) is det.
%%  command(+Database, +Query, +ReturnFields, -Doc) is det.
%
%   True if Doc is the response to Query issued on Database, with
%   the optional ReturnFields being the only fields returned in Doc.

command(Database, Query, Doc) :-
    command(Database, Query, [], Doc).

command(Database, Query, ReturnFields, Doc) :-
    database_cmd_collection(Database, CmdColl),
    mongo_find:find_one(CmdColl, Query, ReturnFields, Doc).

%%  get_last_error(+Database, -Doc) is det.
%
%   True if Doc is a document describing the status of the latest query
%   issued on Database.

get_last_error(Database, Doc) :-
    command(Database, [getlasterror-1], Doc).

%%  drop_database(+Database) is det.
%
%   True if Database is dropped. Throws an exception if Database could
%   not be dropped.
%
%   @throws mongo_error(Description, [ErrorDoc])

drop_database(Database) :-
    command(Database, [dropDatabase-1], Doc),
    doc_ok(Doc),
    !.
drop_database(Database) :-
    mongo_database:database_name(Database, DatabaseName),
    throw(mongo_error('could not drop database', [DatabaseName])).

%%  drop_collection(+Collection) is det.
%
%   True if Collection is dropped from its database. Throws an exception
%   if Collection could not be dropped.
%
%   @throws mongo_error(Description, [ErrorDoc])

drop_collection(Collection) :-
    mongo_collection:collection_database(Collection, Database),
    mongo_collection:collection_name(Collection, CollectionName),
    command(Database, [drop-CollectionName], Doc),
    doc_ok(Doc),
    !.
drop_collection(Collection) :-
    mongo_collection:collection_name(Collection, CollectionName),
    throw(mongo_error('could not drop collection', [CollectionName])).

%%  list_database_names(+Connection, -Names) is det.
%
%   True if Names is a list of names of all logical databases issued
%   over Connection.

list_database_names(Connection, Names) :-
    list_database_infos(Connection, Infos),
    bson:doc_keys(Infos, Names).

%%  list_database_infos(+Connection, -Infos) is det.
%
%   True if Infos is a list of documents detailing all logical databases
%   issued over Connection.

list_database_infos(Connection, Infos) :-
    admin_database(DatabaseName),
    mongo_connection:get_database(Connection, DatabaseName, Database),
    command(Database, [listDatabases-1], Doc),
    bson:doc_get(Doc, databases, InfoArray),
    repack_database_infos(InfoArray, Infos).

repack_database_infos([], []).
repack_database_infos([[name-Name|Info]|Infos], [Name-Info|Names]) :-
    repack_database_infos(Infos, Names).

%%  list_commands(+Database, -Commands) is det.
%
%   True if Commands is a list of documents detailing the commands that
%   can be executed on Database.

list_commands(Database, Result) :-
    command(Database, [listCommands-1], [commands-1], Result).

%%  list_collection_names(+Database, -Names) is det.
%
%   True if Names is the list of collection names in Database.
%
%   @tbd XXX This currently only returns the first batch of
%   collection names, and I'm unsure how large that batch is.

list_collection_names(Database, Names) :-
    command(Database, [listCollections-1], Doc),
    Doc = [cursor-Cursor|_],
    Cursor = [id-_CursorId,ns-_CursorNamespace,firstBatch-Collections|_],
    repack_collection_infos(Collections, Names).

repack_collection_infos([], []).
repack_collection_infos([[name-Name|_]|Colls], [Name|Names]) :-
    repack_collection_infos(Colls, Names).

%%  doc_ok(+Doc) is semidet.
%
%   True if Doc is marked as okay.

doc_ok(Doc) :-
    bson:doc_get_strict(Doc, ok, Value),
    doc_ok_value(Value).

doc_ok_value(1.0).
