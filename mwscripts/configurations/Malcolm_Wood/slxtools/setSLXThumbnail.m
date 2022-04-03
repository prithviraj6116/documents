function setSLXThumbnail(slx_file,thumbnail_file)
    resolved_slx_file = i_resolve(slx_file);
    resolved_thumbnail_file = i_resolve(thumbnail_file);
    partdef = struct('PartName','/metadata/thumbnail.png',...
        'ContentType','image/png',...
        'ParentPartName','',...
        'RelationshipType','http://schemas.openxmlformats.org/package/2006/relationships/metadata/thumbnail',...
        'RelationshipID','Thumbnail');
    
    sls_writepart(resolved_slx_file,resolved_thumbnail_file,partdef);

end

function resolved = i_resolve(filename)
    resolved = which(filename);
    if isempty(resolved)
        resolved = dependencies.absolute_filename(filename);
        if ~exist(resolved,'file')
            error('mwood:tools:setSLXThumbnail','File not found: %s\n',filename);
        end
    end
end