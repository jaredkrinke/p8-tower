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

local player_states = {
    on_ground = 1,
    jumping = 2,
    falling = 3,
}

player = {
    state = player_states.falling,
    jump_held_last = false,

    x = 64,
    y = 64,
    w = 8,
    h = 8,

    bounds_offset = 1,

    vx = 0,
    vy = 0,

    ax = 15 / 256,
    ax_reverse = 2 / 16,
    vx_max = 1.5,

    ay = 5 / 16,
    ay_jump = 1 / 16,
    vy_max = 4 + 5 / 16,
}

function player:get_jump_speed()
    local speed = abs(self.vx)
    if speed > 3 then
        return 3 + 15 / 16
    elseif speed > 2 then
        return 3 + 11 / 16
    elseif speed > 1 then
        return 3 + 9 / 16
    end

    return 3 + 7 / 16
end

function player:get_bounds_y()
    local x, y = self.x, self.y
    return x + self.bounds_offset, x + self.w - 1 - self.bounds_offset, y - self.h + 1, y
end

function player:get_bounds_x()
    local x, y = self.x, self.y
    return x, x + self.w - 1, y - self.h + 1 + self.bounds_offset, y - self.bounds_offset
end

function player:update()
    local moving_left = (self.vx < 0)
    local moving_right = (self.vx > 0)
    local left_held = btn(buttons.left)
    local right_held = btn(buttons.right)
    local jump_held = btn(buttons.z)
    local jump_pressed = not self.jump_held_last and jump_held
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
    local x1, x2, y1, y2 = self:get_bounds_x()
    local bx1, by1 = world:to_map(x1, y1)
    local bx2, by2 = world:to_map(x2, y2)
    -- todo: squish
    for i=1, 2 do
        local bx = nil
        local offset = nil
        if i == 1 then
            bx, offset = bx1, 8
        else
            bx, offset = bx2, - self.w
        end

        for by=by1, by2 do
            if world:get(bx, by) ~= 0 then
                self.vx = 0
                local bxw, byw = world:from_map(bx, by)
                self.x = bxw + offset
                break
            end
        end
    end

    -- jumping
    local ay = self.ay
    if self.state == player_states.on_ground then
        if jump_pressed then
            self.vy = -self:get_jump_speed()
            self.state = player_states.jumping
        end
    elseif self.state == player_states.jumping then
        if self.vy >= -2 then
            self.state = player_states.falling
        end

        if jump_held and self.vy < -2 then
            ay = self.ay_jump
        end
    end

    -- y axis collisions
    self.vy = self.vy + ay
    self.y = self.y + self.vy
    local x1, x2, y1, y2 = self:get_bounds_y()
    local bx1, by1 = world:to_map(x1, y1)
    local bx2, by2 = world:to_map(x2, y2)
    -- todo: squish
    for i=1, 2 do
        local by = nil
        local offset = nil
        if i == 1 then
            by, offset = by1, 8 + self.h - 1
        else
            by, offset = by2, -1
        end

        for bx=bx1, bx2 do
            if world:get(bx, by) ~= 0 then
                self.vy = 0
                local bxw, byw = world:from_map(bx, by)
                self.y = byw + offset
                self.state = i == 1 and player_states.falling or player_states.on_ground
                break
            end
        end
    end

    self.jump_held_last = jump_held
end

world = {
}

function world:get(bx, by)
    if by >= 16 then
        return 1
    elseif by == 15 then
        return bx % 3 == 0 and 1 or 0
    elseif by == 13 then
        return bx % 4 == 0 and 1 or 0
    end
    return 0
end

function world:to_map(x, y)
    return flr(x / 8) + 1, flr(y / 8) + 1
end

function world:from_map(bx, by)
    return (bx - 1) * 8, (by - 1) * 8
end

function world:get_pixel(x, y)
    local bx, by = self:to_map(x, y)
    return self:get(bx, by)
end

function _update60()
    player:update()
end

function player:draw()
    rectfill(self.x, self.y - self.h + 1, self.x + self.w - 1, self.y, colors.red)
    local x1, x2, y1, y2 = self:get_bounds_y()
    rectfill(x1, y1, x2, y2, colors.green)
    local x1, x2, y1, y2 = self:get_bounds_x()
    rectfill(x1, y1, x2, y2, colors.blue)
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

    print("(" .. flr(player.x) .. ", " .. flr(player.y) .. ")", 0, 0, colors.white)
end

