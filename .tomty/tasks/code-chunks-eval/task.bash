#!bash

cat $root_dir/task.bash

cat << 'HERE' > $cache_root_dir/code.md
```{raku}
my $answer = 42;
```
HERE

raku examples/file-code-chunks-eval.raku  \
--evalOutputPrompt="## OUTPUT :: " \
--evalErrorPrompt="## ERROR :: " \
-o=$cache_root_dir/out.md $cache_root_dir/code.md

echo "==="

cat $cache_root_dir/out.md
