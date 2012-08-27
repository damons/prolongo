:- module(mongo_update,
    [
        upsert/3,
        update/3,
        update/4,
        update_all/3
    ]).

/** <module> Document updating.
 */

:- include(misc(common)).

%%  upsert(+Collection, +Selector, +Modifier).
%
%   True if the first document in Collection matching Selector is updated
%   according to Modifier. If no such document exists, it is created with
%   the Selector as a base and Modifier applied to it.

upsert(Collection, Selector, Modifier) :-
    update(Collection, Selector, Modifier, [upsert]).

%%  update_all(+Collection, +Selector, +Modifier).
%
%   True if all documents in Collection matching Selector is updated
%   according to Modifier.

update_all(Collection, Selector, Modifier) :-
    update(Collection, Selector, Modifier, [multi]).

%%  update(+Collection, +Selector, +Modifier).
%
%   True if the first document in Collection matching Selector is updated
%   according to Modifier.

update(Collection, Selector, Modifier) :-
    update(Collection, Selector, Modifier, []).

update(Collection, Selector, Modifier, Options) :-
    mongo_collection:collection_namespace(Collection, Namespace),
    mongo_util:options_to_bitmask(Options, mongo_update:option_value, Flags),
    build_bytes_for_update(Namespace, Selector, Modifier, Flags, BytesToSend),
    mongo_collection:collection_connection(Collection, Connection),
    mongo_connection:send_to_server(Connection, BytesToSend).

build_bytes_for_update(Namespace, Selector, Modifier, Flags, Bytes) :-
    phrase(build_bytes_for_update(Namespace, Selector, Modifier, Flags), Bytes),
    mongo_bytes:count_bytes_and_set_length(Bytes).

build_bytes_for_update(Namespace, Selector, Modifier, Flags) -->
    mongo_bytes:header(000, 000, 2001), % xxxxx request, response
    mongo_bytes:int32(0), % ZERO.
    mongo_bytes:c_string(Namespace),
    mongo_bytes:int32(Flags),
    mongo_bytes:bson_doc(Selector),
    mongo_bytes:bson_doc(Modifier).

option_value(upsert, 1).
option_value(multi,  2).
