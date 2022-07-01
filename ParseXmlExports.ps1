class FileSystemFile {
    [string]$SysId;
    [string]$FileName;
    [string]$ContentType;
    [int]$Position;
    [long]$Length;
    [string]$CreatedBy;
    [DateTime]$CreatedOn;
    static [System.Collections.Generic.Dictionary[string,FileSystemFile]]$Files = [System.Collections.Generic.Dictionary[string,FileSystemFile]]::new();
    static [FileSystemFile] Import([string]$RootPath, [string]$BaseName, [string]$Extension, [string]$ContentType, [System.Xml.XmlElement]$XmlElement) {
        $id = '' + $XmlElement.sys_id;
        if ([FileSystemFile]::Files.ContainsKey($id)) { return [FileSystemFile]::new([FileSystemFile]::Files[$id]) }
        $n = $BaseName + $Extension;
        $Path = [System.IO.Path]::Combine($RootPath, $n);
        if ([System.IO.File]::Exists($Path)) {
            $i = 0;
            do {
                $i++;
                $n = "$BaseName$i$Extension";
                $Path = [System.IO.Path]::Combine($RootPath, $n);
            } while ([System.IO.File]::Exists($Path));
        }
        $Data = ('' + $XmlElement.data).Trim();
        [FileSystemFile]$Result = $null;
        if ($ContentType -eq 'application/base64') {
            [System.IO.File]::WriteAllText($Path, $Data, [System.Text.UTF8Encoding]::new($false, $false));
            $Result = [FileSystemFile]::new($n, $ContentType, $XmlElement);
        } else {
            try {
                $Bytes = [System.Convert]::FromBase64String($Data);
                [System.IO.File]::WriteAllBytes($Path, $Bytes);
                $Result = [FileSystemFile]::new($n, $ContentType, $XmlElement);
            } catch {
                Write-Warning -Message "Error decoding from $id`: $_";
                $n = "$BaseName.mim";
                $Path = [System.IO.Path]::Combine($RootPath, $n);
                if ([System.IO.File]::Exists($Path)) {
                    $i = 0;
                    do {
                        $i++;
                        $n = "$BaseName$i.mim";
                        $Path = [System.IO.Path]::Combine($RootPath, $n);
                    } while ([System.IO.File]::Exists($Path));
                }
                [System.IO.File]::WriteAllText($Path, $Data, [System.Text.UTF8Encoding]::new($false, $false));
                $Result = [FileSystemFile]::new($n, 'application/base64', $XmlElement);
            }
        }
        [FileSystemFile]::Files.Add($id, $Result);
        return $Result;
    }
    FileSystemFile([string]$FileName, [string]$ContentType, [System.Xml.XmlElement]$XmlElement) {
        $this.FileName = $FileName;
        $this.ContentType = $ContentType;
        $this.SysId = '' + $XmlElement.sys_id;
        $s = '' + $XmlElement.length;
        $v = 0;
        if ([string]::IsNullOrWhiteSpace($s) -or -not [int]::TryParse($s, [ref]$v)) {
            $this.Position = 0;
        } else {
            $this.Position = $v;
        }
        [long]$l = 0;
        if ([string]::IsNullOrWhiteSpace($s) -or -not [long]::TryParse($s, [ref]$l)) {
            $this.Length = ([long]0);
        } else {
            $this.Length = $l;
        }
        $this.CreatedBy = '' + $XmlElement.sys_created_by;
        $this.CreatedOn = [DateTime]::Parse($XmlElement.sys_created_on);
    }
    FileSystemFile([FileSystemFile]$Source) {
        $this.FileName = $Source.FileName;
        $this.ContentType = $Source.ContentType;
        $this.SysId = $Source.SysId;
        $this.Position = $Source.Position;
        $this.Length = $Source.Length;
        $this.CreatedBy = $Source.CreatedBy;
        $this.CreatedOn = $Source.CreatedOn;
    }
}

class SysAttachment {
    [string]$SysId;
    [string]$FileName;
    [string]$ContentType;
    [string]$AverageImageColor;
    [long]$Length;
    [string]$TableName;
    [string]$CreatedBy;
    [DateTime]$CreatedOn;
    [string]$UpdatedBy;
    [DateTime]$UpdatedOn;
    [FileSystemFile[]]$Files;
    SysAttachment([System.Xml.XmlElement]$XmlElement) {
        $this.SysId = '' + $XmlElement.sys_id;
        $this.FileName = '' + $XmlElement.file_name;
        $this.ContentType = '' + $XmlElement.content_type;
        $this.AverageImageColor = '' + $XmlElement.average_image_color;
        $s = '' + $XmlElement.size_bytes;
        [long]$l = 0;
        if ([string]::IsNullOrWhiteSpace($s) -or -not [long]::TryParse($s, [ref]$l)) {
            $this.Length = ([long]0);
        } else {
            $this.Length = $l;
        }
        $this.CreatedBy = '' + $XmlElement.sys_created_by;
        $this.CreatedOn = [DateTime]::Parse($XmlElement.sys_created_on);
        $this.UpdatedBy = '' + $XmlElement.sys_updated_by;
        $this.UpdatedOn = [DateTime]::Parse($XmlElement.sys_updated_on);
        $this.TableName = '' + $XmlElement.table_name;
    }
}

[xml]$AttachmentsDocument = '<unload />';
$AttachmentsDocument.Load(($PSScriptRoot | Join-Path -ChildPath 'exports\sys_attachment.xml'));
[xml]$FilesDocument = '<unload />';
$FilesDocument.Load(($PSScriptRoot | Join-Path -ChildPath 'exports\sys_attachment_doc.xml'));

$RootPath = $PSScriptRoot | Join-Path -ChildPath 'out\attachments';
[char[]]$InvalidFileNameChars = [System.IO.Path]::GetInvalidFileNameChars();
[SysAttachment[]]$AttachmentObjects = @($AttachmentsDocument.SelectNodes('unload/sys_attachment') | ForEach-Object {
    $SysAttachment = [SysAttachment]::new($_);
    $Height = -1;
    $Width = -1;
    $s = '' + $XmlElement.image_height;
    $v = -1;
    if ([string]::IsNullOrWhiteSpace($s) -or -not [int]::TryParse($s, [ref]$v)) { $v = -1 }
    if ($v -ge 0) { $this.Height = $v }
    $s = '' + $XmlElement.image_width;
    $v = -1;
    if ([string]::IsNullOrWhiteSpace($s) -or -not [int]::TryParse($s, [ref]$v)) { $v = -1 }
    if ($v -ge 0) { $this.Width = $v }
    $BaseName = $SysAttachment.FileName.Trim();
    $Extension = '';
    if ($BaseName.Length -eq 0) {
        $BaseName = $SysAttachment.SysId;
    } else {
        if ($BaseName.IndexOfAny($InvalidFileNameChars) -ge 0) {
            $StringBuilder = [System.Text.StringBuilder]::new();
            for ($i = 0; $i -lt $BaseName.Length; $i++) {
                $c = $BaseName[$i];
                if ($InvalidFileNameChars -ccontains $c) {
                    $v = [char]::ConvertToUtf32($BaseName, $i);
                    if ($v -ge 0 -and $v -le 0xff) {
                        $StringBuilder.Append('_').Append($v.ToString('x2')).Append('_') | Out-Null;
                    } else {
                        $StringBuilder.Append('_').Append($v.ToString('x4')).Append('_') | Out-Null;
                    }
                } else {
                    $StringBuilder.Append($c) | Out-Null;
                }
            }
            $BaseName = $StringBuilder.ToString();
        }
        $Extension = [System.IO.Path]::GetExtension($BaseName);
        if ($Extension.Length -eq 0) {
            if ($BaseName.EndsWith('.')) {
                if ($BaseName -eq '.') { $BaseName = $SysAttachment.SysId } else { $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($BaseName) }
            }
        } else {
            $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($BaseName);
        }
    }
    $FileContentType = $SysAttachment.ContentType;
    if ([string]::IsNullOrWhiteSpace($Extension)) {
        switch ($FileContentType) {
            'audio/aac' { $Extension = '.aac'; break; }
            'application/x-abiword' { $Extension = '.abw'; break; }
            'application/x-freearc' { $Extension = '.arc'; break; }
            'image/avif' { $Extension = '.avif'; break; }
            'video/x-msvideo' { $Extension = '.avi'; break; }
            'application/vnd.amazon.ebook' { $Extension = '.azw'; break; }
            'application/octet-stream' { $Extension = '.bin'; break; }
            'image/bmp' { $Extension = '.bmp'; break; }
            'application/x-bzip' { $Extension = '.bz'; break; }
            'application/x-bzip2' { $Extension = '.bz2'; break; }
            'application/x-cdf' { $Extension = '.cda'; break; }
            'application/x-csh' { $Extension = '.csh'; break; }
            'text/css' { $Extension = '.css'; break; }
            'text/csv' { $Extension = '.csv'; break; }
            'application/msword' { $Extension = '.doc'; break; }
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document' { $Extension = '.docx'; break; }
            'application/vnd.ms-fontobject' { $Extension = '.eot'; break; }
            'application/epub+zip' { $Extension = '.epub'; break; }
            'application/gzip' { $Extension = '.gz'; break; }
            'image/gif' { $Extension = '.gif'; break; }
            'text/html' { $Extension = '.html'; break; }
            'image/vnd.microsoft.icon' { $Extension = '.ico'; break; }
            'text/calendar' { $Extension = '.ics'; break; }
            'application/java-archive' { $Extension = '.jar'; break; }
            'image/jpeg' { $Extension = '.jpg'; break; }
            'text/javascript' { $Extension = '.js'; break; }
            'application/json' { $Extension = '.json'; break; }
            'application/ld+json' { $Extension = '.jsonld'; break; }
            'audio/midi' { $Extension = '.midi'; break; }
            'audio/x-midi' { $Extension = '.midi'; break; }
            'application/base64' { $Extension = '.mim'; break; }
            'text/javascript' { $Extension = '.mjs'; break; }
            'audio/mpeg' { $Extension = '.mp3'; break; }
            'video/mp4' { $Extension = '.mp4'; break; }
            'video/mpeg' { $Extension = '.mpeg'; break; }
            'application/vnd.apple.installer+xml' { $Extension = '.mpkg'; break; }
            'application/vnd.oasis.opendocument.presentation' { $Extension = '.odp'; break; }
            'application/vnd.oasis.opendocument.spreadsheet' { $Extension = '.ods'; break; }
            'application/vnd.oasis.opendocument.text' { $Extension = '.odt'; break; }
            'audio/ogg' { $Extension = '.oga'; break; }
            'video/ogg' { $Extension = '.ogv'; break; }
            'application/ogg' { $Extension = '.ogx'; break; }
            'audio/opus' { $Extension = '.opus'; break; }
            'font/otf' { $Extension = '.otf'; break; }
            'image/png' { $Extension = '.png'; break; }
            'application/pdf' { $Extension = '.pdf'; break; }
            'application/x-httpd-php' { $Extension = '.php'; break; }
            'application/vnd.ms-powerpoint' { $Extension = '.ppt'; break; }
            'application/vnd.openxmlformats-officedocument.presentationml.presentation' { $Extension = '.pptx'; break; }
            'application/vnd.rar' { $Extension = '.rar'; break; }
            'application/rtf' { $Extension = '.rtf'; break; }
            'application/x-sh' { $Extension = '.sh'; break; }
            'image/svg+xml' { $Extension = '.svg'; break; }
            'application/x-shockwave-flash' { $Extension = '.swf'; break; }
            'application/x-tar' { $Extension = '.tar'; break; }
            'image/tiff' { $Extension = '.tiff'; break; }
            'video/mp2t' { $Extension = '.ts'; break; }
            'font/ttf' { $Extension = '.ttf'; break; }
            'text/plain' { $Extension = '.txt'; break; }
            'application/vnd.visio' { $Extension = '.vsd'; break; }
            'audio/wav' { $Extension = '.wav'; break; }
            'audio/webm' { $Extension = '.weba'; break; }
            'video/webm' { $Extension = '.webm'; break; }
            'image/webp' { $Extension = '.webp'; break; }
            'font/woff' { $Extension = '.woff'; break; }
            'font/woff2' { $Extension = '.woff2'; break; }
            'application/xhtml+xml' { $Extension = '.xhtml'; break; }
            'application/vnd.ms-excel' { $Extension = '.xls'; break; }
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' { $Extension = '.xlsx'; break; }
            'application/xml' { $Extension = '.xml'; break; }
            'application/vnd.mozilla.xul+xml' { $Extension = '.xul'; break; }
            'application/zip' { $Extension = '.zip'; break; }
            'video/3gpp' { $Extension = '.3gp'; break; }
            'audio/3gpp' { $Extension = '.3gp'; break; }
            'video/3gpp2' { $Extension = '.3g2'; break; }
            'audio/3gpp2' { $Extension = '.3g2'; break; }
            'application/x-7z-compressed' { $Extension = '.7z'; break; }
            'image/svg+xml' { $Extension = '.svg'; break; }
            default {
                $FileContentType = 'application/base64';
                $Extension = '.mim';
                break;
            }
        }
    } else {
        if ($FileContentType.Trim().Length -eq 0) {
            switch ($Extension.ToLower()) {
                '.aac' { $FileContentType = 'audio/aac'; break; }
                '.abw' { $FileContentType = 'application/x-abiword'; break; }
                '.arc' { $FileContentType = 'application/x-freearc'; break; }
                '.avif' { $FileContentType = 'image/avif'; break; }
                '.avi' { $FileContentType = 'video/x-msvideo'; break; }
                '.azw' { $FileContentType = 'application/vnd.amazon.ebook'; break; }
                '.bin' { $FileContentType = 'application/octet-stream'; break; }
                '.bmp' { $FileContentType = 'image/bmp'; break; }
                '.bz' { $FileContentType = 'application/x-bzip'; break; }
                '.bz2' { $FileContentType = 'application/x-bzip2'; break; }
                '.cda' { $FileContentType = 'application/x-cdf'; break; }
                '.csh' { $FileContentType = 'application/x-csh'; break; }
                '.css' { $FileContentType = 'text/css'; break; }
                '.csv' { $FileContentType = 'text/csv'; break; }
                '.doc' { $FileContentType = 'application/msword'; break; }
                '.docx' { $FileContentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'; break; }
                '.eot' { $FileContentType = 'application/vnd.ms-fontobject'; break; }
                '.epub' { $FileContentType = 'application/epub+zip'; break; }
                '.gz' { $FileContentType = 'application/gzip'; break; }
                '.gif' { $FileContentType = 'image/gif'; break; }
                '.html' { $FileContentType = 'text/html'; break; }
                '.ico' { $FileContentType = 'image/vnd.microsoft.icon'; break; }
                '.ics' { $FileContentType = 'text/calendar'; break; }
                '.jar' { $FileContentType = 'application/java-archive'; break; }
                '.jpg' { $FileContentType = 'image/jpeg'; break; }
                '.js' { $FileContentType = 'text/javascript'; break; }
                '.json' { $FileContentType = 'application/json'; break; }
                '.jsonld' { $FileContentType = 'application/ld+json'; break; }
                '.midi' { $FileContentType = 'audio/midi'; break; }
                '.midi' { $FileContentType = 'audio/x-midi'; break; }
                '.mim' { $FileContentType = 'application/base64'; break; }
                '.mjs' { $FileContentType = 'text/javascript'; break; }
                '.mp3' { $FileContentType = 'audio/mpeg'; break; }
                '.mp4' { $FileContentType = 'video/mp4'; break; }
                '.mpeg' { $FileContentType = 'video/mpeg'; break; }
                '.mpkg' { $FileContentType = 'application/vnd.apple.installer+xml'; break; }
                '.odp' { $FileContentType = 'application/vnd.oasis.opendocument.presentation'; break; }
                '.ods' { $FileContentType = 'application/vnd.oasis.opendocument.spreadsheet'; break; }
                '.odt' { $FileContentType = 'application/vnd.oasis.opendocument.text'; break; }
                '.oga' { $FileContentType = 'audio/ogg'; break; }
                '.ogv' { $FileContentType = 'video/ogg'; break; }
                '.ogx' { $FileContentType = 'application/ogg'; break; }
                '.opus' { $FileContentType = 'audio/opus'; break; }
                '.otf' { $FileContentType = 'font/otf'; break; }
                '.png' { $FileContentType = 'image/png'; break; }
                '.pdf' { $FileContentType = 'application/pdf'; break; }
                '.php' { $FileContentType = 'application/x-httpd-php'; break; }
                '.ppt' { $FileContentType = 'application/vnd.ms-powerpoint'; break; }
                '.pptx' { $FileContentType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'; break; }
                '.rar' { $FileContentType = 'application/vnd.rar'; break; }
                '.rtf' { $FileContentType = 'application/rtf'; break; }
                '.sh' { $FileContentType = 'application/x-sh'; break; }
                '.svg' { $FileContentType = 'image/svg+xml'; break; }
                '.swf' { $FileContentType = 'application/x-shockwave-flash'; break; }
                '.tar' { $FileContentType = 'application/x-tar'; break; }
                '.tiff' { $FileContentType = 'image/tiff'; break; }
                '.ts' { $FileContentType = 'video/mp2t'; break; }
                '.ttf' { $FileContentType = 'font/ttf'; break; }
                '.txt' { $FileContentType = 'text/plain'; break; }
                '.vsd' { $FileContentType = 'application/vnd.visio'; break; }
                '.wav' { $FileContentType = 'audio/wav'; break; }
                '.weba' { $FileContentType = 'audio/webm'; break; }
                '.webm' { $FileContentType = 'video/webm'; break; }
                '.webp' { $FileContentType = 'image/webp'; break; }
                '.woff' { $FileContentType = 'font/woff'; break; }
                '.woff2' { $FileContentType = 'font/woff2'; break; }
                '.xhtml' { $FileContentType = 'application/xhtml+xml'; break; }
                '.xls' { $FileContentType = 'application/vnd.ms-excel'; break; }
                '.xlsx' { $FileContentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'; break; }
                '.xml' { $FileContentType = 'application/xml'; break; }
                '.xul' { $FileContentType = 'application/vnd.mozilla.xul+xml'; break; }
                '.zip' { $FileContentType = 'application/zip'; break; }
                '.3gp' { $FileContentType = 'video/3gpp'; break; }
                '.3gp' { $FileContentType = 'audio/3gpp'; break; }
                '.3g2' { $FileContentType = 'video/3gpp2'; break; }
                '.3g2' { $FileContentType = 'audio/3gpp2'; break; }
                '.7z' { $FileContentType = 'application/x-7z-compressed'; break; }
                '.svg' { $FileContentType = 'image/svg+xml'; break; }
                default { $FileContentType = 'application/octet-stream'; break; }
            }
        }
    }
    $SysAttachment.Files = ([FileSystemFile[]](
        @($AttachmentsDocument.SelectNodes("unload/sys_attachment_doc[sys_attachment/@sys_id=`"$($SysAttachment.SysId)`"]") | ForEach-Object { [FileSystemFile]::Import($RootPath, $BaseName, $Extension, $FileContentType, $_) }) +
        @($FilesDocument.SelectNodes("unload/sys_attachment_doc[sys_attachment/@sys_id=`"$($SysAttachment.SysId)`"]") | ForEach-Object { [FileSystemFile]::Import($RootPath, $BaseName, $Extension, $FileContentType, $_) })
    ));
    $SysAttachment | Write-Output;
});

$AttachmentObjects | ConvertTo-Json;
<#
		301	300	cbf17d01db45fb00b53f341f7c961916	image/jpeg	24197	d	2	2019-04-24 18:42:01	Communication10A.jpg	2019-04-24 18:42:01	0ff17d01db45fb00b53f341f7c961916	2019-04-24 18:42:01	0	22144	

#>