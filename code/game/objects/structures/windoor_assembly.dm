/* Windoor (window door) assembly -Nodrak
 * Step 1: Create a windoor out of rglass
 * Step 2: Add r-glass to the assembly to make a secure windoor (Optional)
 * Step 3: Rotate or Flip the assembly to face and open the way you want
 * Step 4: Wrench the assembly in place
 * Step 5: Add cables to the assembly
 * Step 6: Set access for the door.
 * Step 7: Screwdriver the door to complete
 */


/obj/structure/windoor_assembly
	icon = 'icons/obj/doors/windoor.dmi'

	name = "windoor Assembly"
	icon_state = "l_windoor_assembly01"
	anchored = 0
	density = 0
	dir = NORTH

	var/ini_dir
	var/obj/item/weapon/airlock_electronics/electronics = null
	var/created_name = null

	//Vars to help with the icon's name
	var/facing = "l"	//Does the windoor open to the left or right?
	var/secure = 0		//Whether or not this creates a secure windoor
	var/state = "01"	//How far the door assembly has progressed

/obj/structure/windoor_assembly/New(dir=NORTH)
	..()
	ini_dir = dir
	air_update_turf(1)

/obj/structure/windoor_assembly/Destroy()
	density = 0
	air_update_turf(1)
	..()

/obj/structure/windoor_assembly/Move()
	var/turf/T = loc
	..()
	move_update_air(T)

/obj/structure/windoor_assembly/update_icon()
	icon_state = "[facing]_[secure ? "secure_" : ""]windoor_assembly[state]"

/obj/structure/windoor_assembly/CanPass(atom/movable/mover, turf/target, height=0)
	if(istype(mover) && mover.checkpass(PASSGLASS))
		return 1
	if(get_dir(loc, target) == dir) //Make sure looking at appropriate border
		return !density
	else
		return 1

/obj/structure/windoor_assembly/CanAtmosPass(var/turf/T)
	if(get_dir(loc, T) == dir)
		return !density
	else
		return 1

/obj/structure/windoor_assembly/CheckExit(atom/movable/mover as mob|obj, turf/target as turf)
	if(istype(mover) && mover.checkpass(PASSGLASS))
		return 1
	if(get_dir(loc, target) == dir)
		return !density
	else
		return 1


/obj/structure/windoor_assembly/attackby(obj/item/W as obj, mob/user as mob, params)
	//I really should have spread this out across more states but thin little windoors are hard to sprite.
	add_fingerprint(user)
	switch(state)
		if("01")
			if(istype(W, /obj/item/weapon/weldingtool) && !anchored )
				var/obj/item/weapon/weldingtool/WT = W
				if (WT.remove_fuel(0,user))
					user.visible_message("[user] disassembles the windoor assembly.", "<span class='notice'>You start to disassemble the windoor assembly...</span>")
					playsound(loc, 'sound/items/Welder2.ogg', 50, 1)

					if(do_after(user, 40))
						if(!src || !WT.isOn()) return
						user << "<span class='notice'>You disassemble the windoor assembly.</span>"
						var/obj/item/stack/sheet/rglass/RG = new (get_turf(src), 5)
						RG.add_fingerprint(user)
						if(secure)
							var/obj/item/stack/rods/R = new (get_turf(src), 4)
							R.add_fingerprint(user)
						qdel(src)
				else
					return

			//Wrenching an unsecure assembly anchors it in place. Step 4 complete
			if(istype(W, /obj/item/weapon/wrench) && !anchored)
				for(var/obj/machinery/door/window/WD in loc)
					if(WD.dir == dir)
						user << "<span class='warning'>There is already a windoor in that location!</span>"
						return
				playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
				user.visible_message("[user] secures the windoor assembly to the floor.", "<span class='notice'>You start to secure the windoor assembly to the floor...</span>")

				if(do_after(user, 40))
					if(!src || anchored)
						return
					for(var/obj/machinery/door/window/WD in loc)
						if(WD.dir == dir)
							user << "<span class='warning'>There is already a windoor in that location!</span>"
							return
					user << "<span class='notice'>You secure the windoor assembly.</span>"
					anchored = 1
					if(secure)
						name = "secure anchored windoor assembly"
					else
						name = "anchored windoor assembly"

			//Unwrenching an unsecure assembly un-anchors it. Step 4 undone
			else if(istype(W, /obj/item/weapon/wrench) && anchored)
				playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
				user.visible_message("[user] unsecures the windoor assembly to the floor.", "<span class='notice'>You start to unsecure the windoor assembly to the floor...</span>")

				if(do_after(user, 40))
					if(!src || !anchored)
						return
					user << "<span class='notice'>You unsecure the windoor assembly.</span>"
					anchored = 0
					if(secure)
						name = "secure windoor assembly"
					else
						name = "windoor assembly"

			//Adding plasteel makes the assembly a secure windoor assembly. Step 2 (optional) complete.
			else if(istype(W, /obj/item/stack/sheet/plasteel) && !secure)
				var/obj/item/stack/sheet/plasteel/P = W
				if(P.amount < 2)
					user << "<span class='warning'>You need more plasteel to do this!</span>"
					return
				user << "<span class='notice'>You start to reinforce the windoor with plasteel...</span>"

				if(do_after(user,40))
					if(!src || secure)
						return

					P.use(2)
					user << "<span class='notice'>You reinforce the windoor.</span>"
					secure = 1
					if(anchored)
						name = "secure anchored windoor assembly"
					else
						name = "secure windoor assembly"

			//Adding cable to the assembly. Step 5 complete.
			else if(istype(W, /obj/item/stack/cable_coil) && anchored)
				user.visible_message("[user] wires the windoor assembly.", "<span class='notice'>You start to wire the windoor assembly...</span>")

				if(do_after(user, 40))
					if(!src || !anchored || state != "01")
						return
					var/obj/item/stack/cable_coil/CC = W
					if(!CC.use(1))
						user << "<span class='warning'>You need more cable to do this!</span>"
						return
					user << "<span class='notice'>You wire the windoor.</span>"
					state = "02"
					if(secure)
						name = "secure wired windoor assembly"
					else
						name = "wired windoor assembly"
			else
				..()

		if("02")

			//Removing wire from the assembly. Step 5 undone.
			if(istype(W, /obj/item/weapon/wirecutters))
				playsound(loc, 'sound/items/Wirecutter.ogg', 100, 1)
				user.visible_message("[user] cuts the wires from the airlock assembly.", "<span class='notice'>You start to cut the wires from airlock assembly...</span>")

				if(do_after(user, 40))
					if(!src || state != "02")
						return

					user << "<span class='notice'>You cut the windoor wires.</span>"
					new/obj/item/stack/cable_coil(get_turf(user), 1)
					state = "01"
					if(secure)
						name = "secure anchored windoor assembly"
					else
						name = "anchored windoor assembly"

			//Adding airlock electronics for access. Step 6 complete.
			else if(istype(W, /obj/item/weapon/airlock_electronics))
				if(!user.drop_item())
					return
				playsound(loc, 'sound/items/Screwdriver.ogg', 100, 1)
				user.visible_message("[user] installs the electronics into the airlock assembly.", "<span class='notice'>You start to install electronics into the airlock assembly...</span>")
				W.loc = src

				if(do_after(user, 40))
					if(!src || electronics)
						W.loc = loc
						return
					user << "<span class='notice'>You install the airlock electronics.</span>"
					name = "near finished windoor assembly"
					electronics = W
				else
					W.loc = loc

			//Screwdriver to remove airlock electronics. Step 6 undone.
			else if(istype(W, /obj/item/weapon/screwdriver))
				if(!electronics)
					return

				playsound(loc, 'sound/items/Screwdriver.ogg', 100, 1)
				user.visible_message("[user] removes the electronics from the airlock assembly.", "<span class='notice'>You start to uninstall electronics from the airlock assembly...</span>")

				if(do_after(user, 40))
					if(!src || !electronics)
						return
					user << "<span class='notice'>You remove the airlock electronics.</span>"
					name = "wired windoor assembly"
					var/obj/item/weapon/airlock_electronics/ae
					ae = electronics
					electronics = null
					ae.loc = loc

			else if(istype(W, /obj/item/weapon/pen))
				var/t = stripped_input(user, "Enter the name for the door.", name, created_name,MAX_NAME_LEN)
				if(!t)
					return
				if(!in_range(src, usr) && loc != usr)
					return
				created_name = t
				return



			//Crowbar to complete the assembly, Step 7 complete.
			else if(istype(W, /obj/item/weapon/crowbar))
				if(!electronics)
					usr << "<span class='warning'>The assembly is missing electronics!</span>"
					return
				usr << browse(null, "window=windoor_access")
				playsound(loc, 'sound/items/Crowbar.ogg', 100, 1)
				user.visible_message("[user] pries the windoor into the frame.", "<span class='notice'>You start prying the windoor into the frame...</span>")

				if(do_after(user, 40))

					if(loc && electronics)

						density = 1 //Shouldn't matter but just incase
						user << "<span class='notice'>You finish the windoor.</span>"

						if(secure)
							var/obj/machinery/door/window/brigdoor/windoor = new /obj/machinery/door/window/brigdoor(loc)
							if(facing == "l")
								windoor.icon_state = "leftsecureopen"
								windoor.base_state = "leftsecure"
							else
								windoor.icon_state = "rightsecureopen"
								windoor.base_state = "rightsecure"
							windoor.dir = dir
							windoor.density = 0

							if(electronics.use_one_access)
								windoor.req_one_access = electronics.conf_access
							else
								windoor.req_access = electronics.conf_access
							windoor.electronics = electronics
							electronics.loc = windoor
							if(created_name)
								windoor.name = created_name
							qdel(src)
							windoor.close()


						else
							var/obj/machinery/door/window/windoor = new /obj/machinery/door/window(loc)
							if(facing == "l")
								windoor.icon_state = "leftopen"
								windoor.base_state = "left"
							else
								windoor.icon_state = "rightopen"
								windoor.base_state = "right"
							windoor.dir = dir
							windoor.density = 0

							windoor.req_access = electronics.conf_access
							windoor.electronics = electronics
							electronics.loc = windoor
							if(created_name)
								windoor.name = created_name
							qdel(src)
							windoor.close()


			else
				..()

	//Update to reflect changes(if applicable)
	update_icon()


//Rotates the windoor assembly clockwise
/obj/structure/windoor_assembly/verb/revrotate()
	set name = "Rotate Windoor Assembly"
	set category = "Object"
	set src in oview(1)
	if(usr.stat || !usr.canmove || usr.restrained())
		return
	if (anchored)
		usr << "<span class='warning'>It is fastened to the floor; therefore, you can't rotate it!</span>"
		return 0
	//if(state != "01")
		//update_nearby_tiles(need_rebuild=1) //Compel updates before

	dir = turn(dir, 270)

	//if(state != "01")
		//update_nearby_tiles(need_rebuild=1)

	ini_dir = dir
	update_icon()
	return

//Flips the windoor assembly, determines whather the door opens to the left or the right
/obj/structure/windoor_assembly/verb/flip()
	set name = "Flip Windoor Assembly"
	set category = "Object"
	set src in oview(1)
	if(usr.stat || !usr.canmove || usr.restrained())
		return

	if(facing == "l")
		usr << "<span class='notice'>The windoor will now slide to the right.</span>"
		facing = "r"
	else
		facing = "l"
		usr << "<span class='notice'>The windoor will now slide to the left.</span>"

	update_icon()
	return
