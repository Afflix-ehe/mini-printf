TARGET = mini-printf
SRC = mini-printf.s

$(TARGET): $(SRC)
	gcc -nostdlib -static -o $(TARGET) $(SRC)

clean:
	rm -f $(TARGET)

.PHONY: clean
