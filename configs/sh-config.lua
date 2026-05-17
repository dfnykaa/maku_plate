Config = {}

Config.Framework = "esx" -- Options: ("esx", "qb")
Config.PlateItem = "vehicle_plate" -- Item name
Config.EmptyPlate = "        "
Config.OnlyOwner = false -- If true, players can only remove plates from vehicles they own
Config.AllowedTypes = {
    ['automobile'] = true,
    ['bike'] = true,
    ['boat'] = false,
    ['heli'] = false,
    ['plane'] = false,
    ['submarine'] = false,
    ['trailer'] = true,
    ['train'] = false
}
Config.TargetTakeOff = "Take off plate" -- ox_target label
Config.ClosestVehicleRange = 5.0 -- ox_target distance
Config.Locales = { -- Locale
    ['inventory_full'] = "Your inventory is too full!",
    ['no_vehicle'] = "No vehicle found nearby!",
    ['vehicle_not_allowed'] = "You cannot remove the plate from this type of vehicle!",
    ['no_plate'] = "This vehicle does not have a license plate!",
    ['already_removed'] = "License plate is already gone!",
    ['inside_vehicle'] = "You cannot do this while inside the vehicle!",
    ['too_far'] = "You are too far from the vehicle!",
    ['not_owner'] = "This vehicle does not belong to you!",
    ['wrong_plate'] = "This plate does not belong to this vehicle!",
    ['no_matching_plate'] = "You do not have the matching license plate!",
    ['action_cancelled'] = "Action cancelled!",
    ['plate_removed'] = "License plate removed!",
    ['plate_attached'] = "License plate attached!",
    ['remove_failed'] = "Could not add license plate to inventory!",
    ['attach_failed'] = "Failed to attach license plate!",
    ['taking_off'] = "Taking off plate...",
    ['putting_on'] = "Putting on plate...",
}
