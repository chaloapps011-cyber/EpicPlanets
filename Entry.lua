
-- EPIC PLANETS | Entry.lua
-- Sistema de Passaporte de Entrada

local Entry = {}

Entry.RequiredEntries = {
    'print("script")',
    'print("hello")'
}

function Entry.Validate(code)
    if type(code) ~= "string" then
        return false, "Código inválido."
    end

    for _, entry in ipairs(Entry.RequiredEntries) do
        if not code:find(entry, 1, true) then
            return false, "Passaporte inválido: falta " .. entry
        end
    end

    return true, "Passaporte de entrada aprovado!"
end

return Entry
