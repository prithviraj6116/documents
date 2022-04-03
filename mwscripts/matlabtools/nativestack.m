function nativestack%(s,prune)
% nativestack - Prints the current C++ stack trace

% Get the C++ stack trace and decode it.
s = slsvInternal('NativeStack');
% return;
output = decodestack(s);
printstack(output,true,false);

