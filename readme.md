# Spinner tool entity ( Copyright 2016 ME )

![SpinnerTool](https://raw.githubusercontent.com/dvdvideo1234/SpinnerTool/master/data/pictures/screenshot.jpg)

#### What does this thing do ?
This entity defines a fidget spinner inside the game Garry's mod.
It can use prop for a spinner by creating a bunch for circular [forces][force_ref]
to spin the physics model around.

#### Why did you make this ?
Do you remember when the spinner was such modern [thing](https://en.wikipedia.org/wiki/Fidget_spinner)?

#### We already have motor and wheel tool, why did you this, seriously ?
I made this SENT by request of a friend [Alex Chosen](steamcommunity.com/id/AlexChosen) and it fixes the following problems:
1. General motor tool persisting in Gmod has tendency to rotate in the opposite way when
the car is faced south-north
2. Wire motor tool has strange behavior when the motor is duped or the spinning part
receives high angular velocities
3. Wheels do not have round shape so they bounce on high torques

#### How can I control this scripted entity ?
That's fairly easy. There is a dedicated spinner tool already in `Construction/Spinner Tool`.
  1. **Create** a spinner [IN_ATTACK ( Def: Left click )](https://wiki.garrysmod.com/page/Enums/IN) \
    When you trace a prop it will be automatically be constrained relative to the\
      mass-center to the trace when you use one option from the `Constraint type` combo box\
      besides skipping the constraint all around via `Skip linking`\
    When you trace the world, it will just spawn it on the map.
  2. **Update** a spinner [IN_ATTACK ( Def: Left click )](https://wiki.garrysmod.com/page/Enums/IN) \
    This is done for every parameter except the modified collision radius to
      avoid making lua errors in the [think hook](https://wiki.garrysmod.com/page/GM/Think). This option actually destroys
      the physics object and creates new again, so your contraption [constraints](https://wiki.garrysmod.com/page/constraint)
      will just fail if I am to update that parameter
  3. **Select** a prop to use as a spinner [IN_ATTACK2 ( Def: Right click )](https://wiki.garrysmod.com/page/Enums/IN) \
    When tracing a valid `prop_physics`, the trace [normal vector](https://en.wikipedia.org/wiki/Normal_(geometry)) will become the
      [spin axis][axis_ref] the right player vector will become force lever and their [cross product][cross_ref]
      will result in the force direction. The model will also get selected
  4. **Copy** spinner settings [IN_ATTACK2 ( Def: Right click )](https://wiki.garrysmod.com/page/Enums/IN) \
    When tracing a spinner, you can copy all its internal setup values and
      apply these to other entity of the same class `sent_spinner`

#### What are the lever and axis directions ?
A: Using this you can chose:
  1. [Spin axis][axis_ref] is the local [vector][vector_ref] to use for an axis
  a.k.a the vector which the spinner revolves around.
  2. [Lever][force_ref] is the local [vector][vector_ref] which is used as a
  force offset origin affecting the angle for starting the force [lever][lever_ref] creation.\
  [The cross product][cross_ref] between (1) and (2) defines
  where the direction of the [force][force_ref] is pointing at. If you do not want to define your own vectors,
  you can use the already pre-defined values by selecting a [direction][direction_ref] with a sign attached:

![#R][ref_cl_red]   ```+X ( Red ..) --> Forward local vector``` .\
![#G][ref_cl_green] ```+Y ( Green ) --> Left local vector``` .\
![#B][ref_cl_blue]  ```+Z ( Blue .) --> Up local vector``` .\
![#R][ref_cl_red]   ```-X (  Red ..) --> Back local vector``` .\
![#G][ref_cl_green] ```-Y ( Green ) --> Right local vector``` .\
![#B][ref_cl_blue]  ```-Z ( Blue .) --> Down local vector``` .

These colors are representing all axises default chosen ones.
If you want to use your custom lever or axis u can select the `<Custom>`
option. That way the vectors which you select via model select right click
will be applied on the new spinner.

#### How can I read the tool HUD properly. It displays some lines and circles ?
You have basically two HUD modes:
1. When you trace a spinner
* The center position will be displayed with a yellow circle.
* The [lever][lever_ref] arm(s), using green line(s) ( yes, you can have only\
      one arm to the max of 360 ) with the exact length stored in the SENT.
* Lever [forces][force_ref] are scaled to the max value 50k, as\
      there is red part, which shows the scale of the whole, maximum\
      [force][force_ref] available and yellow part, which shows the amount of [force][force_ref]\
      used relative to the maximum ( Half red and half yellow means 50%\
      of the maximum power input a.k.a 25k gfu)
2. When you trace a ordinary prop of class ```prop_physics```
* It will show the [force][force_ref] (red), [axis][axis_ref] (blue) and [lever][lever_ref] (green)\
vectors that will be used for the user customizable setup option

#### I just created a fidget spinner but when I hit the forward numpad key and it goes in reverse ?
Keep in mind that if you apply negative power, the torque will be reversed when using the numpad.\
The [wire input](https://github.com/wiremod/wire/blob/master/lua/wire/server/wirelib.lua#L106) is independent. It does not take the
numpad direction into consideration as the value includes sign and magnitude.

#### Does this thing have some kind of tweaks ?
Well yeah, you can play around with these using the console
```
  sbox_maxspinner_drofs  --> The offset unit direction vector magnitude to prevent displacement
  sbox_maxspinner_scale  --> Maximum scale for power and lever
  sbox_maxspinner_mass   --> The maximum mass the entity can have
  sbox_maxspinner_radius --> Maximum radius when rebuilding the collision model as sphere
  sbox_maxspinner_line   --> Maximum linear offset for panel and clamping on the tool script
  sbox_maxspinner_broad  --> Maximum time [ms] when reached the think method sends client stuff
  sbox_maxspinner_tick   --> Maximum sampling time [ms] when the spinner is activated. Be careful!
  sbox_enspinner_remerr  --> When enabled removes the spinner when an error is present
  sbox_enspinner_wdterr  --> When enabled turns on the watchdog timer error
  sbox_enspinner_timdbg  --> When enabled outputs the rate status on the wire output
```
* The [watchdog timer](https://en.wikipedia.org/wiki/Watchdog_timer) will be activated when the program in the think
  hook takes more time to execute than the actual entity tick interval chosen
* For using the timer debug array as a wire output, the user must set the convar
  to enabled, then create a spinner to invoke the initializing method
* The maximum spinner tick is the time between two think hook calls
  and it is used on spinner initialization. Be careful, do not set this too low !

#### May I put this in a third party website ?
Ahh, this again. Emm, NO. I will never give you my permission to do that.\
By doing this, you are forcing people to use an older copy of this script !


### Have a nice time spinning this up !

[force_ref]: https://en.wikipedia.org/wiki/Force
[lever_ref]: https://en.wikipedia.org/wiki/Lever
[axis_ref]: https://en.wikipedia.org/wiki/Rotation_around_a_fixed_axis
[vector_ref]: https://en.wikipedia.org/wiki/Euclidean_vector
[direction_ref]: https://en.wikipedia.org/wiki/Direction_vector
[cross_ref]: https://en.wikipedia.org/wiki/Cross_product
[ref_cl_red]: https://placehold.it/15/ff0000/000000?text=+
[ref_cl_green]: https://placehold.it/15/00ff00/000000?text=+
[ref_cl_blue]: https://placehold.it/15/0000ff/000000?text=+