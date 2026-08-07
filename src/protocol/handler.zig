const parser = @import("parser.zig");

pub fn handleParseResult(result: parser.ParseResult) !parser.Command {
    switch (result) {
        .invalid_magic => {},
        .invalid_opcode => {},
        .command => |command| {
            switch (command) {
                .delete => {},
                .flush => {},
                .set => {},
                .get => {},
                .ping => {},
                .size => {},
            }
        },
    }
}
