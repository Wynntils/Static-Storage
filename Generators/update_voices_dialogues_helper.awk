/s.addSound/ {
    gsub(/\);/, "", $0)
    gsub(/.*s.addSound\(/, "", $0)
    gsub(/^[[:space:]]+/, "", $0)
    print "line: " $0
    next
}
/^ {2,}\/\// {
    gsub(/^[[:space:]]+/, "", $0)
    quest_name = substr($0, index($0, "//") + 2)
    if (index(quest_name, "TODO ") != 0) {
        next
    }
    if (substr(quest_name, 1, 1) == "[") {
        next
    }
    print "quest: \"" quest_name "\""
    next
}
{
    next
}
