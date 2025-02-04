const std = @import("std");

/// Basic sparse matrix in CSR form, heap-allocated.
pub const SimpleCSR = struct {
    /// Heap memory allocator.
    allocator: std.mem.Allocator,
    /// Number of rows in the matrix.
    rows: usize,
    /// Number of columns in the matrix.
    cols: usize,
    /// Array of nonzero values.
    nonzeroes: []f64,
    /// Array of columns these nonzero values are located at.
    colIndices: []usize,
    /// Cumulative numbers of rows occupied by non-zero values.
    rowPointers: []usize,

    /// Initiates an instance of this object. 
    /// All fields are heap-allocated except 'rows' and 'cols' because they are
    /// zero-dimensional objects, thus only scale at O(1) even at very large struct sizes.
    /// Heap-allocating them wastes computational time. We need this struct to be as fast as possible.
    pub fn init(
        allocator: std.mem.Allocator,
        rows: usize,
        cols: usize,
        nonzeroes: []const f64,
        colIndices: []const usize,
        rowPointers: []const usize,
    ) !SimpleCSR {
        // Allocate memory for the CSR arrays
        const nonzeroes_ = try allocator.alloc(f64, nonzeroes.len);
        const colIndices_ = try allocator.alloc(usize, colIndices.len);
        const rowPointers_ = try allocator.alloc(usize, rowPointers.len);

        // Copy the input data into the allocated arrays
        @memcpy(nonzeroes_, nonzeroes);
        @memcpy(colIndices_, colIndices);
        @memcpy(rowPointers_, rowPointers);

        return SimpleCSR{
            .allocator = allocator,
            .rows = rows,
            .cols = cols,
            .nonzeroes = nonzeroes_,
            .colIndices = colIndices_,
            .rowPointers = rowPointers_,
        };
    }

    /// deallocs this struct. Always call this after use.
    /// Idempotency built in to prevent undefined behavior from calling this twice.
    pub fn deinit(self: *SimpleCSR) void {
        if (self.nonzeroes.len > 0) {
            self.allocator.free(self.nonzeroes);
            self.nonzeroes = &[_]f64{};
        }
        if (self.colIndices.len > 0) {
            self.allocator.free(self.colIndices);
            self.colIndices = &[_]usize{};
        }
        if (self.rowPointers.len > 0) {
            self.allocator.free(self.rowPointers);
            self.rowPointers = &[_]usize{};
        }
    }
};

/// Example usage
pub fn main() !void {
    const gpa = std.heap.page_allocator;

    // Example sparse matrix in CSR format
    const nonzeroes = [_]f64{2, 3, 2, 4, 5, 4, 6, 5, 6, 7, 3, 7};
    const colIndices = [_]usize{1, 4, 0, 2, 3, 1, 3, 1, 2, 4, 0, 3};
    const rowPointers = [_]usize{0, 2, 5, 7, 10, 12};

    // Initialize the CSR matrix
    var csr = try SimpleCSR.init(gpa, 5, 5, &nonzeroes, &colIndices, &rowPointers);
    defer csr.deinit();

    std.debug.print("CSR Matrix: rows = {}, cols = {}\n", .{csr.rows, csr.cols});
    std.debug.print("Nonzero values: {d:.1}\n", .{csr.nonzeroes});
    std.debug.print("Column indices: {d:.1}\n", .{csr.colIndices}); 
    std.debug.print("Row pointers cumulative count: {d:.1}\n", .{csr.rowPointers});
}