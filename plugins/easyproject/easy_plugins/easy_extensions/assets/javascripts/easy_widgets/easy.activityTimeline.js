class ActivityTimeline {
  constructor(timelineClass, type) {
    this.timeline = document.querySelector(timelineClass);
    this.heights = [];
    this.eventBoxes = this.timeline
      ? this.timeline.querySelectorAll(".easy-activity-feed__activity-event")
      : null;
    this.timelineType = type;
    this.init();
  }

  init() {
    if (!this.eventBoxes) return;
    if (this.checkMediaQuery()) return;
    this.computeHeights();
    this.recalculatePosition();
  }

  checkMediaQuery() {
    let sassDataBreakpoint;
    if (this.timelineType === "modal") {
      sassDataBreakpoint = ERUI.sassData["breakpoint-xlarge"] || "1400px"
    } else {
      sassDataBreakpoint = ERUI.sassData["breakpoint-medium"] || "960px"
    }
    const mediaQuery = window.matchMedia(`(max-width: ${sassDataBreakpoint})`).matches;
    return mediaQuery;
  }

  computeHeights() {
    this.eventBoxes.forEach(box => {
      box.style.position = "absolute";
      this.heights.push(box.offsetHeight);
    });
  }

  recalculatePosition() {
    // even or odd box rendering
    let evenOdd = 1;
    // 0 => even box, 1 => odd box
    const evenOddSums = [0, 0];
    const gap = 25;
    const bottomPageSpace = 150;
    this.eventBoxes.forEach((box, index) => {
      evenOdd = !evenOdd ? 1 : 0;
      const actualBoxHeight = this.heights[index];
      if (index === 0) {
        evenOddSums[evenOdd] += actualBoxHeight + gap;
        box.style.top = `${gap}px`;
        return;
      }
      const previousBoxTop = parseFloat(this.eventBoxes[index - 1].style.top);
      const prevEvenOdd = this.eventBoxes[index - 2];
      const previousEvenOddBoxTop = prevEvenOdd ? parseFloat(prevEvenOdd.style.top) : null;
      const previousEvenOddBoxHeight = this.heights[index - 2] || null;
      const isNewDay = box.classList.contains("new-day");
      // if box has new day tag => it needs to be moved under previous to tag not overflow prev. box
      if (isNewDay) {
        evenOddSums[evenOdd] = previousBoxTop + this.heights[index - 1] + 2 * gap;
        box.style.top = `${evenOddSums[evenOdd]}px`;
        evenOddSums[evenOdd] += actualBoxHeight;
        return;
      }
      // if previous box is lower than next box => box need to be positioned after previous and at the same time
      // it needs to be under previous odd/even
      if (previousBoxTop >= evenOddSums[evenOdd]) {
        evenOddSums[evenOdd] = previousBoxTop + gap;
        box.style.top = `${evenOddSums[evenOdd]}px`;
        if (!previousEvenOddBoxTop || !previousEvenOddBoxHeight) return;
        if (evenOddSums[evenOdd] < (previousEvenOddBoxTop + previousEvenOddBoxHeight)) {
          evenOddSums[evenOdd] = previousEvenOddBoxTop + previousEvenOddBoxHeight + gap;
          box.style.top = `${evenOddSums[evenOdd]}px`;
        }
        return;
      }
      box.style.top = `${evenOddSums[evenOdd] + gap}px`;
      evenOddSums[evenOdd] += actualBoxHeight + gap;
    });
    // because container have only elements with position absolute, we need to set height to container
    this.timeline.style.height = `${parseFloat(
      this.eventBoxes[this.eventBoxes.length - 1].style.top
    ) + bottomPageSpace}px`;
  }
}

EASY.schedule.late(function() {
  new ActivityTimeline(".easy-activity-feed__activity-event-wrapper");
});
