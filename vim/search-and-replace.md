# Search

```txt
/found
# Go to next matched "found"
n
# Go to previous matched "found"
N
```

# Replace

The `g` after the slash is optional: flags for the vim command. Matched replacements happen immediately after execution.

```txt
# e.g. For current line
:s/found/replaced/g
```

For the whole file

```txt
# e.g. For whole file
:s%/foundall/replacedall/g
```