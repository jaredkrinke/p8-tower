pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- constants
colors = {
    black = 0,
    dark_blue = 1,
    dark_purple = 2,
    dark_green = 3,
    brown = 4,
    dark_gray = 5,
    light_gray = 6,
    white = 7,
    red = 8,
    orange = 9,
    yellow = 10,
    green = 11,
    blue = 12,
    indigo = 13,
    pink = 14,
    peach = 15,
}

buttons = {
    left = 0,
    right = 1,
    up = 2,
    down = 3,
    z = 4,
    x = 5,
}

player = {
    x = 64,
    y = 64,
    w = 8,
    h = 8,

    vx = 0,
    vy = 0,

    ax = 15 / 256,
    ax_reverse = 2 / 16,
    vx_max = 1.5,

    ay = 5 / 16,
}

function player:update()
    local moving_left = (self.vx < 0)
    local moving_right = (self.vx > 0)
    local left_held = btn(buttons.left)
    local right_held = btn(buttons.right)
    local ax = 0

    if right_held then
        if moving_left then
            ax = self.ax_reverse
        else
            ax = self.ax
        end
    elseif left_held then
        if moving_right then
            ax = -self.ax_reverse
        else
            ax = -self.ax
        end
    else
        if moving_left then
            ax = self.ax
        elseif moving_right then
            ax = -self.ax
        end
    end

    self.vx = max(-self.vx_max, min(self.vx_max, self.vx + ax))
    if not right_held and not left_held then
        if (moving_left and self.vx > 0) or (moving_right and self.vx < 0) then
            self.vx = 0
        end
    end

    self.x = self.x + self.vx

    local on_ground = (world:get_pixel(self.x, self.y + 1) ~= 0)
    if not on_ground then
        local ay = self.ay
        self.vy = self.vy + ay

        local y2 = self.y + self.vy
        for y=self.y, y2 do
            if world:get_pixel(self.x, y) == 0 then
                self.y = y
            end
        end
    end
end

world = {
}

function world:get(bx, by)
    if by >= 16 then
        return 1
    end
    return 0
end

function world:get_pixel(x, y)
    return self:get(x / 8 + 1, y / 8 + 1)
end

function _update60()
    player:update()
end

function player:draw()
    rectfill(self.x, self.y - self.h + 1, self.x + self.w - 1, self.y, colors.red)
end

function world:draw()
    for bx = 1, 16 do
        for by = 1, 16 do
            if self:get(bx, by) == 1 then
                rectfill((bx - 1) * 8, (by - 1) * 8, bx * 8 - 1, by * 8 - 1, colors.white)
            end
        end
    end
end

function _draw()
    cls()
    world:draw()
    player:draw()

    print("(" .. flr(player.x) .. ", " .. player.y .. ")", 0, 0, colors.white)
end

