local config = {
    font = render.create_font("Arial", 24, 700),
    binds = {
        x = "buy rifle0; buy rifle1; buy rifle2; buy rifle3; buy rifle4; buy secondary0; buy secondary1; buy secondary2; buy nova; buy elite; buy mp7; buy deagle; buy negev; buy glock; buy mac10; buy p90; buy bizon; buy ak47; buy mp9; buy ssg08; buy p2000; buy p250; buy mp9; buy famas; buy aug; buy mp5-sd; buy xm1014; buy nova; buy zeus",
    }
}

input.set_clipboard(
    'bind x "' .. config.binds.x .. '"\n' 
)

engine.register_on_engine_tick(function()
    local x_offset = 400
    local y_offset = 950
    local line_height = 30

    render.draw_text(config.font, "Lagger on", x_offset, y_offset + 0, 0, 255, 0, 255, 0, 0, 0, 0, 0)
    if input.is_key_down(88) then
        render.draw_text(config.font, "X", x_offset, y_offset + line_height * 2, 255, 255, 0, 255, 0, 0, 0, 0, 0)
    end
end)

engine.register_onunload(function()
    input.set_clipboard("unbind x")
    if config.font and render.destroy_font then
        render.destroy_font(config.font)
    end
    engine.log("Deadmatch lagger unloaded!", 255, 0, 0, 255)
end)