-- AbilityConfig.lua
-- Ubicación en Roblox: ReplicatedStorage.AbilityConfig
-- Fuente única de verdad para el equilibrio de Combate PvP y Habilidades Especiales.

local AbilityConfig = {}

AbilityConfig.Combat = {
	MeleeDamage = 25,
	VIPMeleeDamage = 32,
	MeleeRange = 8.5,
	MeleeCooldown = 0.65,
	KnockbackForce = 28,
	SpawnProtectionSeconds = 5,
	CheckpointSafeRadius = 9,
	HubSafeRadius = 28,
	KillCoinReward = 15,
	SameVictimRewardCooldown = 60
}

AbilityConfig.Abilities = {
	Dash = {
		Id = "Dash",
		Name = "💨 Dash",
		Keybind = Enum.KeyCode.One,
		GamepadKey = Enum.KeyCode.DPadUp,
		Cooldown = 5,
		Duration = 0.25,
		DashSpeed = 68,
		Description = "Impulso rápido hacia adelante para esquivar monstruos o saltos largos."
	},
	Shield = {
		Id = "Shield",
		Name = "🛡️ Escudo",
		Keybind = Enum.KeyCode.Two,
		GamepadKey = Enum.KeyCode.DPadRight,
		Cooldown = 14,
		Duration = 4.5,
		DamageReduction = 0.75,
		Description = "Reduce el daño recibido un 75% y bloquea empujones durante 4.5s."
	},
	EnergyPulse = {
		Id = "EnergyPulse",
		Name = "⚡ Pulso",
		Keybind = Enum.KeyCode.Three,
		GamepadKey = Enum.KeyCode.DPadDown,
		Cooldown = 12,
		Radius = 18,
		MonsterStunSeconds = 4,
		PlayerKnockback = 42,
		PlayerDamage = 15,
		Description = "Onda expansiva que aturde monstruos cercanos por 4s y empuja rivales."
	},
	Invisibility = {
		Id = "Invisibility",
		Name = "👻 Sombra",
		Keybind = Enum.KeyCode.Four,
		GamepadKey = Enum.KeyCode.DPadLeft,
		Cooldown = 18,
		Duration = 5,
		Description = "Vuelve tu avatar semitransparente e indetectable para los monstruos por 5s."
	},
	Trap = {
		Id = "Trap",
		Name = "🕸️ Trampa",
		Keybind = Enum.KeyCode.Z,
		GamepadKey = Enum.KeyCode.ButtonL1,
		Cooldown = 15,
		Lifetime = 20,
		MonsterStunSeconds = 4.5,
		PlayerSlowSeconds = 3.5,
		SlowedWalkSpeed = 9,
		Description = "Coloca una runa en el suelo que congela monstruos o ralentiza rivales."
	}
}

AbilityConfig.OrderedList = {"Dash", "Shield", "EnergyPulse", "Invisibility", "Trap"}

return AbilityConfig
