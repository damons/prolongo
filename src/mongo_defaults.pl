/** <module> MongoDB default settings.
 */

:- module(_, [
    host/1,
    port/1
]).

:- include(include/common).

%%  host(?Host) is semidet.
%
%   True if Host is the default hostname used by MongoDB.

host(localhost).

%%  port(?Port) is semidet.
%
%   True if Port is the default port used by MongoDB.

port(27017).
