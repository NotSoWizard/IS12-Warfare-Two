//////////////////////////////
//Contents: Ladders, Stairs.//
//////////////////////////////

/obj/structure/ladder
	name = "ladder"
	icon_state = "ladder01"
	icon = 'icons/obj/structures.dmi'
	density = 0
	opacity = 0
	anchored = 1
	pixel_y = 10


	var/allowed_directions = DOWN
	var/obj/structure/ladder/target_up
	var/obj/structure/ladder/target_down

	var/const/climb_time = 2 SECONDS
	var/static/list/climbsounds = list('sound/effects/ladder.ogg','sound/effects/ladder2.ogg','sound/effects/ladder3.ogg','sound/effects/ladder4.ogg')

/obj/structure/ladder/Initialize()
	. = ..()
	// the upper will connect to the lower
	if(allowed_directions & DOWN) //we only want to do the top one, as it will initialize the ones before it.
		for(var/obj/structure/ladder/L in GetBelow(src))
			if(L.allowed_directions & UP)
				target_down = L
				L.target_up = src
				return
	update_icon()

/obj/structure/ladder/Destroy()
	if(target_down)
		target_down.target_up = null
		target_down = null
	if(target_up)
		target_up.target_down = null
		target_up = null
	return ..()

/obj/structure/ladder/attackby(obj/item/C as obj, mob/user as mob)
	climb(user, "up")

/obj/structure/ladder/attack_hand(var/mob/M)
	climb(M, "up")

/obj/structure/ladder/RightClick(mob/user)
	climb(user, "down")

/obj/structure/ladder/attack_ai(var/mob/M)
	var/mob/living/silicon/ai/ai = M
	if(!istype(ai))
		return
	var/mob/observer/eye/AIeye = ai.eyeobj
	if(istype(AIeye))
		instant_climb(AIeye)

/obj/structure/ladder/attack_robot(var/mob/M)
	climb(M, "up")

/obj/structure/ladder/proc/instant_climb(var/mob/M)
	var/target_ladder = getTargetLadder(M)
	if(target_ladder)
		M.forceMove(get_turf(target_ladder))

/obj/structure/ladder/proc/climb(var/mob/M, direction)
	if(!M.may_climb_ladders(src))
		return
	var/obj/structure/ladder/target_ladder
	switch(direction)
		if("up")
			target_ladder = target_up
		if("down")
			target_ladder = target_down
		else
			target_ladder = target_up
	if(!target_ladder)
		to_chat(M, "<span class='notice'>There is nothing here!Try to climb in other direction</span>")
		return
	if(!M.Move(get_turf(src)))
		to_chat(M, "<span class='notice'>You fail to reach \the [src].</span>")
		return

	var/direction_climb = target_ladder == target_up ? "up" : "down"

	for (var/obj/item/grab/G in M)
		G.adjust_position()


	M.visible_message("<span class='notice'>\The [M] begins climbing [direction_climb] \the [src]!</span>",
	"You begin climbing [direction_climb] \the [src]!",
	"You hear the grunting and clanging of a metal ladder being used.")

	target_ladder.audible_message("<span class='notice'>You hear something coming [direction_climb] \the [src]</span>")

	if(do_after(M, climb_time, src))
		climbLadder(M, target_ladder)
		for (var/obj/item/grab/G in M)
			G.adjust_position(force = 1)

/obj/structure/ladder/examine(mob/user)
	. = ..()
	if(target_up && target_down)
		to_chat(user, "There is a way up and down!")
	if(target_up)
		to_chat(user, "There is a way up!")
	if(target_down)
		to_chat(user, "There is a way down!")


/obj/structure/ladder/attack_ghost(var/mob/M)
	instant_climb(M)

/obj/structure/ladder/proc/getTargetLadder(var/mob/M)
	if((!target_up && !target_down) || (target_up && !istype(target_up.loc, /turf) || (target_down && !istype(target_down.loc,/turf))))
		to_chat(M, "<span class='notice'>\The [src] is incomplete and can't be climbed.</span>")
		return
	if(target_down && target_up)
		var/direction = alert(M,"Do you want to go up or down?", "Ladder", "Up", "Down", "Cancel")

		if(direction == "Cancel")
			return

		if(!M.may_climb_ladders(src))
			return

		switch(direction)
			if("Up")
				return target_up
			if("Down")
				return target_down
	else
		return target_down || target_up

/mob/proc/may_climb_ladders(var/ladder)
	if(!Adjacent(ladder))
		to_chat(src, "<span class='warning'>You need to be next to \the [ladder] to start climbing.</span>")
		return FALSE
	if(incapacitated())
		to_chat(src, "<span class='warning'>You are physically unable to climb \the [ladder].</span>")
		return FALSE

	var/carry_count = 0
	for(var/obj/item/grab/G in src)
		if(!G.ladder_carry())
			to_chat(src, "<span class='warning'>You can't carry [G.affecting] up \the [ladder].</span>")
			return FALSE
		else
			carry_count++
	if(carry_count > 1)
		to_chat(src, "<span class='warning'>You can't carry more than one person up \the [ladder].</span>")
		return FALSE

	return TRUE

/mob/observer/ghost/may_climb_ladders(var/ladder)
	return TRUE

/obj/structure/ladder/proc/climbLadder(var/mob/M, var/target_ladder)
	var/turf/T = get_turf(target_ladder)
	for(var/atom/A in T)
		if(!A.CanPass(M, M.loc, 1.5, 0))
			to_chat(M, "<span class='notice'>\The [A] is blocking \the [src].</span>")
			return FALSE
	playsound(src, pick(climbsounds), 50)
	playsound(target_ladder, pick(climbsounds), 50)
	return M.Move(T)

/obj/structure/ladder/CanPass(obj/mover, turf/source, height, airflow)
	return airflow || !density

/obj/structure/ladder/update_icon()
	icon_state = "ladder[!!(allowed_directions & UP)][!!(allowed_directions & DOWN)]"

/obj/structure/ladder/up
	allowed_directions = UP
	icon_state = "ladder10"

/obj/structure/ladder/updown
	allowed_directions = UP|DOWN
	icon_state = "ladder11"

/obj/structure/stairs
	name = "Stairs"
	desc = "Stairs leading to another floor."
	icon = 'icons/obj/sstairs.dmi'
	icon_state = "below"
	density = 0
	opacity = 0
	anchored = 1
	plane = ABOVE_TURF_PLANE
	layer = RUNE_LAYER

/obj/structure/stairs/trenchstairs
	icon_state = "thetrenchescall"

/obj/structure/trenchstairs // the buildable version
	icon = 'icons/obj/sstairs.dmi'
	icon_state = "thetrenchescall"
	anchored = TRUE
	mouse_opacity = FALSE

/obj/structure/stairs/Initialize()
	for(var/turf/turf in locs)
		var/turf/simulated/open/above = GetAbove(turf)
		if(!above)
			warning("Stair created without level above: ([loc.x], [loc.y], [loc.z])")
			return INITIALIZE_HINT_QDEL
		if(!istype(above))
			above.ChangeTurf(/turf/simulated/open)
	. = ..()

/obj/structure/stairs/Uncross(atom/movable/A)
	if(A.dir == dir && upperStep(A.loc))
		// This is hackish but whatever.
		var/turf/target = get_step(GetAbove(A), dir)
		var/turf/source = A.loc
		var/turf/above = GetAbove(A)
		if(above.CanZPass(source, UP) && target.Enter(A, source))
			A.forceMove(target)
			if(isliving(A))
				var/mob/living/L = A
				if(L.pulling)
					L.pulling.forceMove(source)
		else
			to_chat(A, "<span class='warning'>Something blocks the path.</span>")
		return 0
	return 1

/obj/structure/stairs/proc/upperStep(var/turf/T)
	return (T == loc)

/obj/structure/stairs/CanPass(obj/mover, turf/source, height, airflow)
	return airflow || !density

// type paths to make mapping easier.
/obj/structure/stairs/north
	dir = NORTH

/obj/structure/stairs/south
	dir = SOUTH

/obj/structure/stairs/east
	dir = EAST

/obj/structure/stairs/west
	dir = WEST

//2-Tiled stairs
/obj/structure/stairs/zlong
	name = "Stairs"
	desc = "Not too useful if the gravity goes out."
	icon = 'icons/obj/stairs.dmi'

/obj/structure/stairs/zlong/north
	dir = NORTH
	bound_height = 64
	bound_y = -32
	pixel_y = -32

/obj/structure/stairs/zlong/south
	dir = SOUTH
	bound_height = 64

/obj/structure/stairs/zlong/east
	dir = EAST
	bound_width = 64
	bound_x = -32
	pixel_x = -32

/obj/structure/stairs/zlong/west
	dir = WEST
	bound_width = 64
