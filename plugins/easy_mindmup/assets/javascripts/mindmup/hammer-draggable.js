/*global $, Hammer*/
/*jslint newcap:true*/
EASY.schedule.require(function ($) {
  'use strict';
  $.fn.simpleDraggableContainer = function () {
    var currentDragObject,
        originalDragObjectPosition,
        originalScroll,
        container = this,
        drag = function (event) {

          if (currentDragObject && event.gesture) {
            var currentScroll = $(document).scrollTop();
            var newpos = {
              top: Math.round(originalDragObjectPosition.top + event.gesture.deltaY - originalScroll + currentScroll),
              left: Math.round(originalDragObjectPosition.left + event.gesture.deltaX)
            };
            currentDragObject.offset(newpos).trigger($.Event('mm:drag', {
              currentPosition: newpos,
              gesture: event.gesture
            }));
            return false;
          }
        },
        rollback = function (e) {
          var target = currentDragObject; // allow it to be cleared while animating
          if (target.attr('mapjs-drag-role') !== 'shadow') {
            target.animate(originalDragObjectPosition, {
              complete: function () {
                target.trigger($.Event('mm:cancel-dragging', {gesture: e.gesture}));
              },
              progress: function () {
                target.trigger('mm:drag');
              }
            });
          } else {
            target.trigger($.Event('mm:cancel-dragging', {gesture: e.gesture}));
          }
        };
    return this.on('mm:start-dragging', function (event) {
      if (!currentDragObject) {
        currentDragObject = $(event.relatedTarget);
        //originalDragObjectPosition = {
        //  top: currentDragObject.css('top'),
        //  left: currentDragObject.css('left')
        //};
        originalScroll = $(document).scrollTop();
        originalDragObjectPosition = currentDragObject.offset();
        $(this).on('panmove', drag);
      }
    }).on('mm:start-dragging-shadow', function (event) {
      var target = $(event.relatedTarget),
          clone = function () {
            var result = target.clone().addClass('drag-shadow').appendTo(container).offset(target.offset()).data(target.data()).attr('mapjs-drag-role', 'shadow'),
                scale = target.parent().data('scale') || 1;
            if (scale !== 0) {
              result.css({
                'transform': 'scale(' + scale + ')',
                'transform-origin': 'top left'
              });
            }
            return result;
          };
      if (!currentDragObject) {
        currentDragObject = clone();
        //originalDragObjectPosition = {
        //  top: currentDragObject.css('top'),
        //  left: currentDragObject.css('left')
        //};
        originalScroll = $(document).scrollTop();
        originalDragObjectPosition = currentDragObject.offset();
        currentDragObject.on('mm:stop-dragging mm:cancel-dragging', function (e) {
          $(this).remove();
          e.stopPropagation();
          e.stopImmediatePropagation();
          var evt = $.Event(e.type, {
            gesture: e.gesture,
            finalPosition: e.finalPosition
          });
          target.trigger(evt);
        }).on('mm:drag', function (e) {
          target.trigger(e);
        });
        $(this).on('panmove', drag);
      }
    }).on('panend', function (e) {
      $(this).off('panmove', drag);
      if (currentDragObject) {
        var evt = $.Event('mm:stop-dragging', {
          gesture: e.gesture,
          finalPosition: currentDragObject.offset()
        });
        currentDragObject.trigger(evt);
        if (evt.result === false) {
          rollback(e);
        }
        currentDragObject = undefined;
      }
    }).on('mouseleave', function (e) {
      if (currentDragObject) {
        $(this).off('panmove', drag);
        rollback(e);
        currentDragObject = undefined;
      }
    }).attr('data-drag-role', 'container');
  };

  var onDrag = function (e) {
    $(this).trigger(
        $.Event('mm:start-dragging', {
          relatedTarget: this,
          gesture: e.gesture
        })
    );
    e.stopPropagation();
    e.preventDefault();
  }, onShadowDrag = function (e) {
    $(this).trigger(
        $.Event('mm:start-dragging-shadow', {
          relatedTarget: this,
          gesture: e.gesture
        })
    );
    e.stopPropagation();
    e.preventDefault();
  };
  $.fn.simpleDraggable = function (options) {
    if (!options || !options.disable) {
      return MAPJS.enableVerticalPan(this.hammer()).on('panstart', onDrag);
    } else {
      return this.off('panstart', onDrag);
    }
  };
  $.fn.shadowDraggable = function (options) {
    if (!options || !options.disable) {
      return MAPJS.enableVerticalPan(this.hammer()).on('panstart', onShadowDrag);
    } else {
      return this.off('panstart', onShadowDrag);
    }
  };
}, 'jQuery');
