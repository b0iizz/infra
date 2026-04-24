{ lib, ... }:
let
  inherit (lib)
    concatStringsSep
    strings
    removeSuffix
    stringAsChars
    optionalString
    escapeXML
    attrNames
    mapAttrsToList
    attrsToList
    filterAttrs
    filter
    isAttrs
    isList
    isInt
    isBool
    isFloat
    isString
    isPath
    typeOf
    ;
  isSimpleValue =
    value:
    isNull value || isBool value || isInt value || isFloat value || isString value || isPath value;

  formatXML =
    name: value:
    (
      if (isAttrs value) then
        formatXMLAttr
      else if (isList value) then
        formatXMLList
      else
        formatXMLValue
    )
      name
      value;

  formatXMLValue =
    name: value:
    let
      surround =
        inner: if (isNull name) then "'${escapeXML inner}'" else "<${name}>${escapeXML inner}</${name}>";
      valueStr =
        if (isBool value) then
          (if value then "true" else "false")
        else if (isSimpleValue value) then
          toString value
        else
          throw "formatXMLValue: require null, bool, int, float, string or path but got ${typeOf value}";
    in
    "${surround valueStr}";

  formatXMLList = name: value: concatStringsSep "\n" (map (formatXML name) value);

  formatXMLAttr =
    name: value:
    if (isNull name && !(value ? _raw)) then
      formatXMLAttrContent (attrsToList value)
    else
      formatXMLNamedAttr name value;

  space = n: strings.fixedWidthString n " " "";
  indent =
    num: s: removeSuffix (space num) (stringAsChars (c: if c == "\n" then "\n" + (space num) else c) s);
  formatXMLNamedAttr =
    name: value:
    let
      simpleAttributes = filterAttrs (_: isSimpleValue) value;
      attributeString = concatStringsSep " " (
        mapAttrsToList (name: value: "${name}=${formatXML null value}") simpleAttributes
      );

      contentList = value._content or [ ];
      verbatim = value._verbatim or "";
      simpleContent = removeAttrs value (
        [
          "_content"
          "_verbatim"
          "_raw"
        ]
        ++ (attrNames simpleAttributes)
      );
      lines =
        (map ({ name, value }: formatXML name value) (attrsToList simpleContent ++ contentList))
        ++ [ verbatim ];
      innerLines = filter (line: line != "") lines;
      header = "${name}${optionalString (attributeString != "") " "}${attributeString}";
    in
    if (value ? _raw) then
      value._raw
    else if (innerLines == [ ]) then
      "<${header}/>"
    else
      ''
        <${header}>
          ${indent 2 (concatStringsSep "\n" innerLines)}
        </${name}>
      '';

  formatXMLAttrContent = values: ''
    ${concatStringsSep "\n" (map ({ name, value }: formatXML name value) values)}
  '';
in
formatXML null
