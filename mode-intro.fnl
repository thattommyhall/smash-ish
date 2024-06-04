(import-macros {: incf} :sample-macros)
(local lume (require :lib.lume))
(local bump (require :lib.bump))
(local inspect (require :lib.inspect))

(local (major minor revision) (love.getVersion))
(local (width height _flags) (love.window.getMode))

(local entities (bump.newWorld))
(local enemies [])
(local bullets [])
(local BLACK [])
(local WHITE [255 255 255 1])

(fn generate-enemy [size]
  (let [enemy {:x (math.random (- width size))
               :y (math.random (- height size))
               :w size
               :h size
               :type :enemy
               :colour [(math.random) (math.random) (math.random) 1]
               :speed 0}]
    (table.insert enemies enemy)
    (entities:add enemy enemy.x enemy.y enemy.w enemy.h)))

(fn shoot-bullet [x y direction speed]
  (let [bullet {:type :bullet
                : x
                : y
                :w 8
                :h 8
                :colour WHITE
                : speed
                : direction}]
    (table.insert bullets bullet)
    (entities:add bullet bullet.x bullet.y bullet.w bullet.h)))

(for [i 1 5]
  (generate-enemy 32))

(local p1 {:x 50
           :y 100
           :w 32
           :h 32
           :colour [1 0 0 1]
           :speed 60
           :direction :up
           :pressed {:w false :s false :a false :d false}
           :last_fired 0})

(shoot-bullet (+ p1.x (/ p1.w 2)) (+ p1.y (/ p1.h 2)) :right 100)

(local world {:time 0 :background_colour [0 0 0 1]})

(entities:add p1 p1.x p1.y p1.w p1.h)

(entities:add {:type :wall :label :top} 0 0 width 1)
(entities:add {:type :wall :label :bottom} 0 (- height 1) width 1)
(entities:add {:type :wall :label :left} 0 0 1 height)
(entities:add {:type :wall :label :right} (- width 1) 0 1 height)

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

(fn update-player [p dt]
  (let [{: x : y : speed} p
        {: w : a : s : d} p.pressed
        direction (decide-direction w a s d)
        [dx dy] (. d-map direction)
        goal_x (+ x (* dx dt speed))
        goal_y (+ y (* dy dt speed))
        (new_x new_y cols ncols) (entities:move p goal_x goal_y)]
    (if (> (length cols) 0)
        (each [_ col (ipairs cols)]
          (if (= :enemy col.other.type)
              (love.event.quit))))
    (tset p :x new_x)
    (tset p :y new_y)))

(fn remove-enemy [enemy]
  (entities:remove enemy)
  (lume.remove enemies enemy))

(fn remove-bullet [bullet]
  (entities:remove bullet)
  (lume.remove bullets bullet))

(fn update-bullet [b dt]
  (let [{: x : y : speed : direction} b
        [dx dy] (. d-map direction)
        goal_x (+ x (* dx dt speed))
        goal_y (+ y (* dy dt speed))
        (new_x new_y cols ncols) (entities:move b goal_x goal_y)]
    (if (> (length cols) 0)
        (each [_ col (ipairs cols)]
          (case col.other.type
            :enemy (remove-enemy col.other)
            :wall (remove-bullet b))))
    (tset b :x new_x)
    (tset b :y new_y)))

(local valid-keys {:w true :s true :a true :d true})

(fn draw-entity [e]
  (let [{: x : y : w : h : colour} e]
    (love.graphics.setColor (unpack colour))
    (love.graphics.rectangle :fill x y w h)))

{:draw (fn draw [message]
         (love.graphics.setColor (unpack world.background_colour))
         (love.graphics.rectangle :fill 0 0 width height)
         (draw-entity p1)
         (each [_ enemy (ipairs enemies)]
           (draw-entity enemy))
         (each [_ bullet (ipairs bullets)]
           (draw-entity bullet)))
 :update (fn update [dt set-mode]
           (tset world :time (+ world.time dt))
           (each [_ bullet (ipairs bullets)]
             (update-bullet bullet dt))
           (update-player p1 dt))
 :keypressed (fn keypressed [key set-mode]
               (print "pressed:" key)
               (if (. valid-keys key)
                   (tset p1.pressed key true)))
 :keyreleased (fn keyreleased [key set-mode]
                (print "released:" key)
                (if (. valid-keys key)
                    (tset p1.pressed key false)))}
