parameter BORDER_COLOR_NORMAL = 16'h7fff;
parameter BORDER_COLOR_DEAD_1 = 16'h7c00;
parameter BORDER_COLOR_DEAD_2 = 16'h7fff;

parameter PLAYER_COLOR = 16'hde2;
parameter OBJECTIVE_COLOR = 16'h7c00;
parameter FONT_COLOR = 16'h0000;
parameter BACKGROUND_COLOR = 16'b000010000100011;

parameter ENTITY_NONE = 2'b00;
parameter ENTITY_PLAYER = 2'b01;
parameter ENTITY_OBJECTIVE = 2'b10;
parameter ENTITY_WALL = 2'b11;

parameter GAME_STATE_ALIVE = 2'b00;
parameter GAME_STATE_DEAD = 2'b01;
parameter GAME_STATE_TODO1 = 2'b10;
parameter GAME_STATE_TODO2 = 2'b11;