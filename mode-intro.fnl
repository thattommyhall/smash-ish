(import-macros {: incf} :sample-macros)
(local lume (require :lib.lume))
(local bump (require :lib.bump))
(local inspect (require :lib.inspect))

(local (major minor revision) (love.getVersion))
(local (width height _flags) (love.window.getMode))

(local bumpworld (bump.newWorld))
(local entities [])
(local BLACK [])
(local WHITE [255 255 255 1])


(fn new-animation [image w h] ;; sprite width and height
  (let [animation {:sprite_sheet image
                   :quads []}
        (img_w img_h) (image:getDimensions)]
    (for [x 0 (- img_h h) h]
      (for [y 0 (- img_w w) w]
        (table.insert animation.quads (love.graphics.newQuad x y w h img_w img_h))))
    animation))

(fn generate-enemy [size]
  (let [x (math.random (- size) width)
        y (if (and (>= x 0) (<= x (- width size))) ;; different regions
              (lume.randomchoice [(math.random (- height size) height)
                                  (math.random (- size) 0)])
              (math.random (- size) height))
        enemy {:x x
               :y y
               :w size
               :h size
               :type :enemy
               :colour [(math.random) (math.random) (math.random) 1]
               :speed 20
               :life 3
               :direction (lume.randomchoice [:up
                                              :down
                                              :left
                                              :right
                                              :upright
                                              :upleft
                                              :downright
                                              :downleft])}]
    (table.insert entities enemy)
    (bumpworld:add enemy enemy.x enemy.y enemy.w enemy.h)))

(fn shoot-bullet [x y direction speed]
  (let [bullet {:type :bullet
                : x
                : y
                :w 8
                :h 8
                :colour WHITE
                : speed
                : direction}]
    (table.insert entities bullet)
    (bumpworld:add bullet bullet.x bullet.y bullet.w bullet.h)))

(for [i 1 5]
  (generate-enemy 32))

(local p1 {:type :player
           :x 50
           :y 100
           :w 32
           :h 32
           :colour [1 0 0 1]
           :speed 60
           :direction :up
           :gun-direction :right
           :pressed {:w false
                     :s false
                     :a false
                     :d false
                     :i false
                     :j false
                     :k false
                     :l false}
           :last-fired 0
           :firing-rate 0.25
           :animations {:up (new-animation (love.graphics.newImage "assets/wizard up.png") 32 32)
                        :down (new-animation (love.graphics.newImage "assets/wizard down.png") 32 32)
                        :left (new-animation (love.graphics.newImage "assets/wizard left.png") 32 32)
                        :right (new-animation (love.graphics.newImage "assets/wizard right.png") 32 32)
                        }})

(shoot-bullet (+ p1.x (/ p1.w 2)) (+ p1.y (/ p1.h 2)) :right 100)
(shoot-bullet (+ p1.x (/ p1.w 2)) (+ p1.y (/ p1.h 2)) :down 100)

(local world {:time 0 :background_colour [0 0 0 1]})

(bumpworld:add p1 p1.x p1.y p1.w p1.h)

(bumpworld:add {:type :wall :label :top} 0 -1 width 1)
(bumpworld:add {:type :wall :label :bottom} 0 height width 1)
(bumpworld:add {:type :wall :label :left} -1 0 1 height)
(bumpworld:add {:type :wall :label :right} width 0 1 height)

(love.graphics.setNewFont 30)

(local d-map {:up [0 -1]
              :down [0 1]
              :left [-1 0]
              :right [1 0]
              :upleft [-1 -1]
              :upright [1 -1]
              :downleft [-1 1]
              :downright [1 1]
              :nothing [0 0]})

(fn decide-direction [...]
  (if (> (lume.count [...] #$) 2)
      :nothing
      (case [...]
        [true true _ _] :upleft
        [true _ _ true] :upright
        [_ true true _] :downleft
        [_ _ true true] :downright
        [true _ _ _] :up
        [_ true _ _] :left
        [_ _ true _] :down
        [_ _ _ true] :right
        [_ _ _ _] :nothing)))

(fn ignore [t]
  (fn [item other]
    (if (= other.type t) :cross :slide)))

(fn entity-center [e]
  (let [{: x : y : w : h} e] ;; assumes entity has x,y,w,h properties
    (values (+ x (/ w 2)) (+ y (/ h 2)))))

(fn calc-new-dir [dx dy]
  (case [(lume.round (/ dx (+ (math.abs dx) 0.00001)) 1)
         (lume.round (/ dy (+ (math.abs dy) 0.00001)) 1)]
    [0 -1] :up
    [0 1] :down
    [-1 0] :left
    [1 0] :right
    [-1 -1] :upleft
    [1 -1] :upright
    [-1 1] :downleft
    [1 1] :downright
    [0 0] :nothing))

(fn center-entity-on [x y w h]
  "Given a coordinate and an (rectangular) entity's width and height, return the x,y coordinates at which it should be drawn."
  (values (- x (/ w 2)) (- y (/ h 2)))) ;; no validation that this is in bounds yet!

(fn remove-entity [e]
  (if (bumpworld:hasItem e)
      (bumpworld:remove e))
  (lume.remove entities e))

(fn update-entity [e dt]
  (let [{: x : y : speed : direction} e
        [dx dy] (. d-map direction)
        goal_x (+ x (* dx dt speed))
        goal_y (+ y (* dy dt speed))
        ignore-fn (case e.type
                    :player (ignore :bullet)
                    :bullet (ignore :player)
                    :enemy (ignore :wall)
                    _ nil)
        (new_x new_y cols ncols) (bumpworld:move e goal_x goal_y ignore-fn)]
    (case e.type
      :bullet (if (> (length cols) 0)
                  (each [_ col (ipairs cols)]
                    (case col.other.type
                      :enemy (do
                               (if (> col.other.life 1)
                                   (tset col.other "life" (- col.other.life 1))
                                   (do (remove-entity col.other)
                                       (generate-enemy 64)))
                               (remove-entity e))
                      :wall (remove-entity e))))
      :enemy (do
               (let [{: x : y} p1 ;; hardcoded player entity
                     dx (- x new_x)
                     dy (- y new_y)]
                 (tset e :direction (calc-new-dir dx dy)))
               ))
    (tset e :x new_x)
    (tset e :y new_y)))

(fn update-player [p dt]
  (let [{: x : y : speed} p
        {: w : a : s : d : i : j : k : l} p.pressed
        direction (decide-direction w a s d)
        gun-direction (decide-direction i j k l)
        [dx dy] (. d-map direction)
        goal_x (+ x (* dx dt speed))
        goal_y (+ y (* dy dt speed))
        (new_x new_y cols ncols) (bumpworld:move p goal_x goal_y
                                                 (ignore :bullet))
        since-fired (- world.time (. p :last-fired))
        should-shoot (> since-fired (. p :firing-rate))
        has-gun-direction (not= gun-direction :nothing)]
    (if (> (length cols) 0)
        (each [_ col (ipairs cols)]
          (if (= :enemy col.other.type)
              (do
                (print "you hit a baddy")
                ;(love.event.quit)
                ))))
    (if (and should-shoot has-gun-direction)
        (let [(p_center_x p_center_y) (entity-center p)
              (bullet_x bullet_y) (center-entity-on p_center_x p_center_y 8 8)] ;; hardcoded bullet w & h!
          (shoot-bullet bullet_x bullet_y gun-direction 200)
          (tset p :last-fired world.time)))
    (tset p :x new_x)
    (tset p :y new_y)
    (tset p :direction direction)))

(local valid-keys {:w true
                   :s true
                   :a true
                   :d true
                   :i true
                   :j true
                   :k true
                   :l true})

(fn get-entity-animation [e]
  (let [animations e.animations]
    (case e.direction
      :up animations.up
      :upright animations.up
      :upleft animations.up
      :left animations.left
      :right animations.right
      :down animations.down
      :downleft animations.down
      :downright animations.down
      :nothing animations.down
      _ (print "problem in getting animations!"))
    ))

(fn draw-entity [e]
  (let [{: x : y : w : h : colour : life : animations} e]
    (if animations
        (let [animation (get-entity-animation e)]
          (love.graphics.draw animation.sprite_sheet (. animation.quads 1) x y))
        (do
          (love.graphics.setColor (unpack colour))
          (love.graphics.rectangle :fill x y w h)
          ))
    (if life
        (let [font (love.graphics.getFont)
              text (love.graphics.newText font life)
              (text_w text_h) (text:getDimensions)
              (e_center_x e_center_y) (entity-center e)
              (text_x text_y) (center-entity-on e_center_x e_center_y text_w text_h)]
          (love.graphics.setColor 1 1 1 1)
          (love.graphics.draw text text_x text_y)))))

{:draw (fn draw [message]
         (love.graphics.setColor (unpack world.background_colour))
         (love.graphics.rectangle :fill 0 0 width height)
         (each [_ e (ipairs entities)]
           (draw-entity e))
         (draw-entity p1))
 :update (fn update [dt set-mode]
           (tset world :time (+ world.time dt))
           (each [_ e (ipairs entities)]
             (update-entity e dt))
           (update-player p1 dt))
 :keypressed (fn keypressed [key set-mode]
               (if (. valid-keys key)
                   (do
                     (print "pressed:" key)
                     (tset p1.pressed key true))))
 :keyreleased (fn keyreleased [key set-mode]
                (if (. valid-keys key)
                    (do
                      (print "released:" key)
                      (tset p1.pressed key false))))}
