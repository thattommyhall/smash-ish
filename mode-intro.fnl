(import-macros {: incf} :sample-macros)
(local lume (require :lib.lume))

(var world {"counter" 0
            "time" 0
            "background_colour" [0 0 0 1]
            "pos" [50 100]}) ;; x y

(love.graphics.setNewFont 30)

(local (major minor revision) (love.getVersion))

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
         (let [(x y) (unpack (. world "pos"))]
           (love.graphics.rectangle :fill x y 64 64))
         )
 :update (fn update [dt set-mode]
           (if (< (. world "counter") 60)
               (tset world "counter" (+ (. world "counter") 1))
               (tset world "counter" 0))
           (tset world "time" (+ (. world "time") dt))
           )
 :keypressed (fn keypressed [key set-mode]
               (let [w (love.keyboard.isDown "w")
                     a (love.keyboard.isDown "a")
                     s (love.keyboard.isDown "s")
                     d (love.keyboard.isDown "d")
                     direction (decide-direction w a s d)]
                 (print direction))
                 )}
