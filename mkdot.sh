DIR=$1
for f in $DIR/*.dot; do
	/usr/local/bin/dot -Tpng -o $f.png $f
done

