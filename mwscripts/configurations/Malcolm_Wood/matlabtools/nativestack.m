function nativestack
% nativestack - Prints the current C++ stack trace

% Get the C++ stack trace and decode it.
s = slsvInternal('NativeStack');
output = decodestack(s);
printstack(output);

