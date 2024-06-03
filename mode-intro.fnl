(import-macros {: incf} :sample-macros)
(local lume (require :lib.lume))

(local world {"counter" 0
            "time" 0
            "background_colour" [0 0 0 1]
            "p1" {
                "pos" [50 100] ;; x y
                "speed" 30
                "direction" :up
            }
            }) 

(love.graphics.setNewFont 30)

(local (major minor revision) (love.getVersion))

(local d-map {
    :up [0 -1]
    :down [0 1]
    :left [-1 0]
    :right [1 0]
    :upleft [-1 -1]
    :upright [1 -1]
    :downleft [-1 1]
    :downright [1 1]
    :nothing [0 0]
})

(fn update-player [p dt]
    (let [
        pos (. p "pos" )
        speed (. p "speed" )
        direction (.  p "direction")
        [old_x old_y] (. p "pos" )
        [dx dy] (. d-map direction)
        new_pos [
            (+ old_x (* dt dx speed))
            (+ old_y (* dt dy speed))
        ]
    ]
        (tset p "pos" new_pos)
    )
    )

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
        [_ _ _ _] :nothing
        )))

{:draw (fn draw [message]
         (local (w h _flags) (love.window.getMode))
         (love.graphics.setColor (unpack (. world "background_colour")))
         (love.graphics.rectangle :fill 0 0 w h)
         (love.graphics.setColor 1 0 0 1) ;; red
         (let [(x y) (unpack (. (. world "p1") "pos"))]
           (love.graphics.rectangle :fill x y 16 16))
         )
 :update (fn update [dt set-mode]
           (tset world "time" (+ (. world "time") dt))
           (update-player (. world "p1") dt)
           )
 :keypressed (fn keypressed [key set-mode]
               (let [w (love.keyboard.isDown "w")
                     a (love.keyboard.isDown "a")
                     s (love.keyboard.isDown "s")
                     d (love.keyboard.isDown "d")
                     direction (decide-direction w a s d)]
                 (tset (. world "p1") "direction" direction)
                 ))}
