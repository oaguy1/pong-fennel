(fn love.load []
  ;; start new thread listening on stdin
  (: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start)

  (global player {:x 10
                  :y 10
                  :dy 0
                  :width 25
                  :height 100
                  :speed 200
                  :score 0})

  (global opponent {:x (- (love.graphics.getWidth) 10 25) 
                    :y 10
                    :width 25
                    :height 100
                    :speed 100
                    :dy 0
                    :score 0})

  (global ball {:x (/ (love.graphics.getWidth) 2)
                :y (love.math.random 100 (love.graphics.getHeight))
                :width 25
                :height 25
                :dx -1
                :dy 1
                :speed 100}))

(fn love.handlers.stdin [line]
  ;; evaluate lines written to stdin as fennel
  (let [(ok val) (pcall fennel.eval line)]
    (print (if ok (fennel.view val) val))))

;; remove acceleration when key released
(fn love.keyreleased [key scancode]
  (when (or (= key :up) (= key :down))
    (set player.dy 0)))

(fn love.update [dt]
  ;; update player position using mouse, calculate player.dy
  (var old-player-pos player.y)
  (var new-player-pos (love.mouse.getY))
  (when (or (< new-player-pos 0)
            (> new-player-pos (- (love.graphics.getHeight) player.height)))
    (set new-player-pos old-player-pos))
  (set player.y new-player-pos)
  (set player.dy (- new-player-pos old-player-pos))


  ;; Update ball position
  (let [new-x-pos (+ ball.x (* ball.dx ball.speed dt))
        new-y-pos (+ ball.y (* ball.dy ball.speed dt))]

    ;; opponent score
    (when (< new-x-pos 0)
      (set opponent.score (+ opponent.score 1))
      (set ball.x (/ (love.graphics.getWidth) 2))
      (set ball.y (love.math.random 100 (love.graphics.getHeight)))
      (set ball.dx -1)
      (set ball.dy 1))

    ;; player score
    (when (> new-x-pos (- (love.graphics.getWidth) ball.width))
      (set player.score (+ player.score 1))
      (set ball.x (/ (love.graphics.getWidth) 2))
      (set ball.y (love.math.random 100 (love.graphics.getHeight)))
      (set ball.dx 1)
      (set ball.dy 1))

    ;; hit floor or ceiling
    (when (or
           (< new-y-pos 0)
           (> new-y-pos (- (love.graphics.getHeight) ball.height)))
      (set ball.dy (* -1 ball.dy)))

    ;; really basic collision detection w/ player paddle
    (when (and (<= new-x-pos (+ player.x player.width))
               (>= new-y-pos player.y)
               (<= new-y-pos (+ player.y player.height)))
      ;; match player acceleration
      (when (and (>= player.dy ball.dx)
                 (>= player.dy 1))
          (set ball.dy (* -1 (math.abs player.dy)))
          (set ball.dx (* -1 (math.abs player.dy))))
      (when (and (< player.dy ball.dx)
                 (< player.dy 1))
          (set ball.dy (* -1 ball.dy))
          (set ball.dx (* -1 ball.dy))))

    ;; really basic collision detection w/ opponent paddle
    (when (and (>= (+ new-x-pos ball.width) opponent.x)
               (>= new-y-pos opponent.y)
               (<= new-y-pos (+ opponent.y opponent.height)))
      (set ball.dx (* -1 ball.dx)))

    (set ball.x (+ ball.x (* ball.dx ball.speed dt)))
    (set ball.y (+ ball.y (* ball.dy ball.speed dt))))


  ;; unreasonably basic opponent ai
  (when (> (+ opponent.y (/ opponent.height 2)) ball.y)
    (set opponent.dy (* -1 (math.abs ball.dy))))
  (when (< (+ opponent.y (/ opponent.height 2)) ball.y)
    (set opponent.dy (math.abs ball.dy)))
  (let [new-y-pos (+ opponent.y (* opponent.dy opponent.speed dt))]
    (when (and
           (>= new-y-pos 0)
           (<= new-y-pos (- (love.graphics.getHeight) opponent.height)))
      (set opponent.y new-y-pos)))
  

  ;; Quit when escape is pressed
  (when (love.keyboard.isDown :escape)
    (love.event.quit)))


(fn love.draw []
  ;; scores
  (love.graphics.print player.score (- (/ (love.graphics.getWidth) 2) 25) 25)
  (love.graphics.print opponent.score (+ (/ (love.graphics.getWidth) 2) 25) 25)

  ;; paddels
  (love.graphics.rectangle "fill" player.x player.y player.width player.height)
  (love.graphics.rectangle "fill" opponent.x opponent.y opponent.width opponent.height)

  ;; ball
  (love.graphics.rectangle "fill" ball.x ball.y ball.width ball.height))
