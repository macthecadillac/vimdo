- Record screen with `ttyrec myrec`
- Convert recording to GIF with `ttygif myrec`
- Look at frames with `gifsicle --unoptimize --explode my.gif`
- Remove frames with `gifsicle --unoptimize my.gif --delete "#start1-end1"
  "#start2-end2" -o out.gif`
