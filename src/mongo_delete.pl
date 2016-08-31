/** <module> Document deletion.
 */

:- module(_, [
    delete/2,
    delete/3
]).

:- include(include/common).

%%  delete(+Collection, +Selector) is det.
%
%   Equivalent to calling delete/3 without options.

delete(Collection, Selector) :-
    delete(Collection, Selector, []).

%%  delete(+Collection, +Selector, +Options) is det.
%
%   True if all documents in Collection matching Selector are deleted
%   using Options (possible: single_remove).

delete(Collection, Selector, Options) :-
    mongo_collection:collection_namespace(Collection, Namespace),
    mongo_util:options_to_bitmask(Options, mongo_delete:option_bitmask, Flags),
    build_bytes_for_delete(Namespace, Selector, Flags, BytesToSend),
    mongo_collection:collection_connection(Collection, Connection),
    mongo_connection:send_to_server(Connection, BytesToSend).

build_bytes_for_delete(Namespace, Selector, Flags, Bytes) :-
    phrase(build_bytes_for_delete(Namespace, Selector, Flags), Bytes),
    mongo_bytes:count_bytes_and_set_length(Bytes).

build_bytes_for_delete(Namespace, Selector, Flags) -->
    % XXX mongo_bytes:header(RequestId, ResponseId, OpCode)
    mongo_bytes:header(000, 000, 2006),
    mongo_bytes:int32(0), % ZERO. Reserved for future use.
    mongo_bytes:c_string(Namespace),
    mongo_bytes:int32(Flags),
    mongo_bytes:bson_doc(Selector).

%   option_bitmask(+Option, ?Bitmask) is semidet.
%
%   True if Bitmask is the bitmask for Option.

option_bitmask(single_remove, 0b1).
