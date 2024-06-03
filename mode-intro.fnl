(import-macros {: incf} :sample-macros)
(local lume (require :lib.lume))

(local world {"counter" 0
            "time" 0
            "background_colour" [0 0 0 1]
            "p1" {
                "pos" [50 100] ;; x y
                "speed" 30
                "direction" :up
                "pressed" {:w false
                           :s false
                           :a false
                           :d false}
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

(fn update-player [p dt]
    (let [
        pos (. p "pos" )
        speed (. p "speed" )
        [w a s d] [
            (. p "pressed" "w")
            (. p "pressed" "a")
            (. p "pressed" "s")
            (. p "pressed" "d")
        ]
        direction (decide-direction w a s d)
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



(local valid-keys {
    "w" true
    "s" true
    "a" true
    "d" true
})

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
               (print "pressed:" key)
               (if (. valid-keys key)
                 (tset (. world "p1" "pressed") key true)
                 ))
 :keyreleased (fn keyreleased [key set-mode]
                (print "released:" key)
                (if (. valid-keys key)
                 (tset (. world "p1" "pressed") key false)
                 ))
}
