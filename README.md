# Vegosh: A fast cache aware KV Store:

## Wire format:

[magic 4 bytes][opcode 1 byte][ 1 byte key len][key][1 byte value len][value]

Read magic
Read Opcode
Read Key Len
Read Key
Read Value Len
Read Value
