module rom_screen (
    input  logic [18:0] address,   // Входной адрес (0...307199)
    output logic [15:0] rgb_out   // Выход 16-бит (RGB565)
);

    // Логика определения координаты X
    // Для VGA 640x480: x = address % 640
    // logic [9:0] x_coord;
    // assign x_coord = address % 19'd640;

    //Комбинационная логика выбора цвета через case
    always_comb begin
        // Разделение 640 пикселей на 5 зон по 128 пикселей каждая
        case (1'b1)
            (address < 128):          rgb_out = 16'hF800; // 1. Красный
            (address < 256):          rgb_out = 16'hFFFF; // 2. Белый
            (address < 384):          rgb_out = 16'h001F; // 3. Синий
            (address < 512):          rgb_out = 16'h07E0; // 4. Зеленый
            (address < 640):          rgb_out = 16'h0000; // 5. Черный
            default:                  rgb_out = 16'h0000; // На всякий случай
        endcase
    end

    // assign rgb_out = 16'hFFFF; 

endmodule
