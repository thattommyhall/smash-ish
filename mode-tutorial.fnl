(import-macros {: incf} :sample-macros)
(local lume (require :lib.lume))
(local bump (require :lib.bump))
(local inspect (require :lib.inspect))

(local (major minor revision) (love.getVersion))
(local (width height _flags) (love.window.getMode))

(fn pp [e]
  (print (inspect e)))

(local valid-keys {:w true
                   :s true
                   :a true
                   :d true
                   :i true
                   :j true
                   :k true
                   :l true})

(love.graphics.setNewFont 30)

{:draw (fn draw [message]
         (local (w h _flags) (love.window.getMode))
         (love.graphics.printf (: "Love Version: %s.%s.%s" :format major minor
                                  revision) 0 10
                               w :center)
         (love.graphics.printf "W A S D to move, I J K L to shoot 
         (press one to start)" 0 (- (/ h 2) 15)
                               w :center)
         (love.graphics.setColor 0 0 0 1))
 :keypressed (fn keypressed [key set-mode]
               (if (. valid-keys key) (set-mode :mode-game)))
 :keyreleased (fn keyreleased [key set-mode]
                :pass)}
