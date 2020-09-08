program cmdaf (input, output);
var i, j: integer;
begin
  READ(j);
  i:=0;
  while (i < j) do
  begin
    if (i div 2 * 2 = i) then 
      WRITE(i)
    else 
      WRITE(i);
    i := i + 1;
  end;
end.