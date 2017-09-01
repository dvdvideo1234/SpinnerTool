# SpinnerTool
Spinner tool entity ( Copyright 2016 ME )

```
Q: What does this thing do ?
A: This entity defines a fidget spinner inside the game Garry's mod.
   It can use prop for a spinner by creating a bunch for circular forces
   to spin the physics model around.

Q: Why did you make this ?
A: Remember this thing: https://en.wikipedia.org/wiki/Fidget_spinner

Q: We already have motor and wheel tool, why did you this, seriously ?
A: I made this SENT by request of a friend ( Alex Chosen ) and it fixes the following problems:
  1. General motor tool persisting in Gmod has tendency to rotate in the opposite way when
     the car is faced south-north
  2. Wire motor tool has strange behavior when the motor is duped or the spinning part
     receives high angular velocities
  3. Wheels do not have round shape so they bounce on high torques

Q: How can I control this scripted entity ?
A: That's fairly easy. There is a dedicated spinner tool already ( Construction/Spinner Tool ).
  a) Creating a spinner ( Left click )
    When you trace a prop it will be automatically constrained relative to the
      mass-center when you use one option from the "Constraint type" combo box
      besides skipping the constraint all around via "Skip linking"
    When you trace the world, it will just spawn it on the map.
  b) Updating a spinner ( Left click )
    This is done for every parameter except the modified collision radius to
      avoid making lua errors in the think hook. This option actually destroys
      the physics object and creates new again, so your contraption will just fail.
  c) Select a prop to use as a spinner ( Right click )
    When tracing a valid physics prop, the trace normal vector will become the
      spin axis, the right player vector will become force lever and their cross
      will result in the force direction. The model will also get selected
  d) Copy spinner settings ( Right click )
    When tracing a spinner, you can copy all its internal setup values and
      apply these to other entity of the same class [sent_spinner]

Q: What are the lever and axis direction ?
A: Using this you can chose:
  a) Which local vector to use for a spin
       axis a.k.a the vector which the spinner revolves around ( Axis direction )
  b) Which direction vector to use as a lever. Beware, that this
       also affects the angle for starting the force lever creation ( Lever direction )
  The cross product between a) and b) defines where the direction of the force is
  pointing at. If you do not want to define your own vectors, you can use the already
  pre-defined values by selecting an axis with a direction sign attached:
    +X ( Red   ) --> Forward local vector
    +Y ( Green ) --> Left local vector
    +Z ( Blue  ) --> Up local vector
    -X ( Red   ) --> Back local vector
    -Y ( Green ) --> Right local vector
    -Z ( Blue  ) --> Down local vector
  These colors are representing all axises default chosen ones.
  If you want to use your custom lever or axis u can select the "<Custom>"
  option. That way the vectors which you select via model select right click
  will be applied on the new spinner.

Q: How can I read the tool HUD properly. It displays some lines and circles ?
A: You have basically two HUD modes:
  a) When you trace a spinner
       The center position will be displayed with a yellow circle.
       The lever arm(s), using green line(s) ( yes, you
         can have only one arm to the max of 360 ) with the exact length
         stored in the SENT.
       Lever forces are scaled to the max value 50 thousand, as
         there is red part, which shows the scale of the whole, maximum
         force available and yellow part, which shows the amount of force
         used relative to the maximum ( Half red and half yellow means 50%
         of the maximum power input a.k.a 25 thousand gfu)
  b) When you trace a prop
       It will show the force (red), axis (blue) and lever (green) vectors
       that will be used for the user customizable setup optoion

Q: I just created a fidget spinner but when I hit the forward numpad key and
   it goes in reverse ?
A: Keep in mind that if you apply negative power, the torque will be reversed
   when using the numpad. The wire input is independent. It does not take the
   numpad direction into consideration as the value includes sign and magnitude.

Q: Does this thing have some kind of tweaks ?
A: Well yeah, you can play around with these using the console
  sbox_maxspinner_scale   --> Maximum scale for power and lever
  sbox_maxspinner_mass    --> The maximum mass the entity can have
  sbox_maxspinner_radius  --> Maximum radius when rebuilding the collision model as sphere
  sbox_maxspinner_line    --> Maximum linear offset for panel and clamping on the tool script
  sbox_maxspinner_broad   --> Maximum time [ms] when reached the think method sends client stuff
  sbox_maxspinner_tick    --> Maximum sampling time [ms] when the spinner is activated. Be careful!
  sbox_enspinner_remerr   --> When enabled removes the spinner when an error is present
  sbox_enspinner_wdterr   --> When enabled turns on the watchdog timer error
  sbox_enspinner_timdbg   --> When enabled outputs the rate status on the wire output
N: The watchdog timer will be activated when the program in the think
     hook takes more time to execute than the actual entity tick integral chosen
   For using the timer debug array as a wire output, the user must set the convar
     to enabled, then create a spinner to invoke the initializing method
   The maximum spinner tick is the time between two think hook calls
     and it is used on spinner initialization. Be careful, do not set this too low !

Q: May I put this in a third party website.
A: Ahh, this again. Emm, NO. I will never give you my permission to do that.
   By doing this, you are forcing people to use an older copy of this script !

```
Have a nice time spinning this up !
